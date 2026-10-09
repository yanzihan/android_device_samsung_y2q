# Cross-repository patches

These changes live outside `device/samsung/y2q` but are required for the device to
work.  Apply them from the root of the corresponding `repo` project:

    cd system/libbase                && git am ../../device/samsung/y2q/patches/libbase-restore-Trim-overload.patch
    cd packages/apps/PhhIms          && git am ../../device/samsung/y2q/patches/phhims-sip-invite-fixes.patch
    cd hardware/qcom-caf/sm8250/audio && git am ../../device/samsung/y2q/patches/audio-hal-adev-set-mode-lock.patch
    cd hardware/samsung             && git am ../../device/samsung/y2q/patches/camera-provider-fixes.patch
    cd device/samsung/sm8250-common && git am ../../device/samsung/y2q/patches/sm8250-common-voip-tx-port.patch

`git apply` works too if the project has local commits on top.

## libbase-restore-Trim-overload.patch

Required for NFC.  Samsung's prebuilt NFC and secure-element blobs reference
`android::base::Trim(std::string const&)`, which Android 14 replaced with a
template.  The template instantiations mangle their argument into the symbol name
and so do not satisfy the reference, and the dynamic linker refuses to load the
blobs at all:

    CANNOT LINK EXECUTABLE "/vendor/bin/hw/nxp.android.hardware.nfc@1.2-service":
        cannot locate symbol "_ZN7android4base4TrimERKNSt3__112basic_string..."
        referenced by "/vendor/lib64/nfc_nci_nxpsn.so"

The usual workaround, preloading a shim that defines the symbol, cannot work here.
init starts the service, SELinux sets `secureexec` on the init -> hal_nfc_default
domain transition (security/selinux/hooks.c), bionic then ignores `LD_PRELOAD`
entirely (linker_main.cpp), and AOSP forbids granting init the `noatsecure`
permission that would suppress it (`neverallow init *:process noatsecure`).  A
launcher that drops privileges itself and execs the HAL is also ruled out:
`hal_neverallows.te` forbids `execute_no_trans` from any HAL domain.

Restoring the overload in libbase is the only route that does not fight the
policy, and it fixes every blob with the same reference.  Note that the vendor
copy at `/vendor/lib64/libbase.so` is the one the vendor process loads, not
`/system/lib64/libbase.so` - patching only the system variant has no effect on the
HAL and is a good way to spend an afternoon.

## phhims-sip-invite-fixes.patch

PhhIms is used as the IMS stack; see the `ims:` commit in this repository for why
there is no vendor ImsService.  Two faults made calls unusable, and both were in
the session descriptions we sent rather than in the signalling around them.

**Calls dropped the moment the far end answered.**  China Unicom's SBC sends a
re-INVITE once the call is up, to renegotiate media for the connected state.
Our answer to it was refused and the dialog was torn down 71 ms later:

    180 Ringing
    (far end answers)
    UPDATE from the SBC
    our 200
    487 Request Terminated, Warning 399 "SDP is illegal"

The cause is a missing CRLF.  RFC 4566 terminates every session description line
with CRLF, including the last, and the SBC enforces it.  Two of the six builders
omitted it and every other one emitted it, which is exactly the split between the
descriptions the SBC accepted and the ones it refused:

| builder | trailing CRLF | result |
| --- | --- | --- |
| `SipOutgoingInviteSdp` | yes | accepted |
| `conservativeAmrNbRetryBody` | yes | accepted |
| `SipIncomingInviteResponses` | yes | accepted |
| `SipInDialogInvite` | yes | accepted |
| `SipUpdateSdpAnswerBuilder` | no | refused, 487 |
| `buildPreconditionUpdateSdp` | no | refused, 400 |

Service numbers and incoming calls never reach that renegotiation, which is why
they worked throughout and made this look like something else.

Four genuine offer/answer faults were fixed alongside it, all in the same
answers: fmtp parameters were invented for payloads the offer sent bare and
ptime was defaulted instead of echoed; the QoS block was emitted even when the
offer carried no preconditions; the answer used its own session id in `o=`
rather than keeping one identity for the dialog; and rtpmap and fmtp lines were
interleaved rather than paired per payload.

**Incoming calls dropped about 150 ms after connecting.**  The operator sends a
re-INVITE with no session description, which RFC 3261 14.2 defines as the peer
asking the UAS to supply the offer.  The parse returned null for the empty body
and the caller read that as "nothing acceptable" and answered 488, so the network
took the dialog down.  It now answers 200 with the session already in use.

## audio-hal-adev-set-mode-lock.patch

`adev_set_mode()` in the audio HAL serialises on a lock that the voice call path
already holds, so `MODE_IN_CALL` is issued late and the call has no audio.  The
patch makes the lock a timed one and logs when it is contended.

## camera-provider-fixes.patch

Three faults kept the camera provider from working at all.  Every non-main-lens
session - ultrawide, telephoto, front, zoomed video - failed with "camera session
error" and took the whole provider down with it.

**SIGPIPE killed the provider.**  The Samsung camera libraries send OEM requests
to the RIL daemon over the `@VND_Multiclient` socket without installing a handler
for SIGPIPE.  When the RIL side closes an idle connection the write takes the
process down silently - no tombstone - and every camera goes with it.  The
provider now ignores SIGPIPE before loading the vendor libraries; SIG_IGN
survives exec, so their writes fail with EPIPE instead, which the camera code
already tolerates.

**The HAL could not write the camera id remap table.**  The kernel driver creates
`/sys/class/camera/rear/supported_cameraIds` as `system:system 0664` and the
Camera Hardware Interface writes the remap into it.  The provider runs as
`cameraserver` with gid `camera`, and the rc listed

    group audio camera input drmrpc usb

so it was not in the owning group:

    [ERROR][HAL] camxchicontext.cpp: EnumerateSensorModes() Unsupported capability
    sysfs open file failed. [/sys/class/camera/rear/supported_cameraIds]
    pResult contains more buffers (1) than the expected number of buffers (0)

The stock provider lists `system` alongside those groups.  With it added the HAL
writes `0 1 2 20 21 23 50 52 80` on startup and the sysfs error stops.

**The zoom stopped at 8x.**  The panel is a 30x-class device, and the libraries
publish `ANDROID_SCALER_AVAILABLE_MAX_DIGITAL_ZOOM` as 8.0.  The fix moved both
that tag and `ANDROID_CONTROL_ZOOM_RATIO_RANGE` to 30.0, but the trigger only
looked for the latter - and this HAL does not emit it at all.  The framework
derives `zoomRatioRange` from the scaler tag, so rewriting the derived one
changes nothing; it is re-derived on every query.  The trigger now accepts
either tag reporting 8.0, and both are moved.  Verified on the device: the
framework then reports `[1.0, 30.0]` and `availableMaxDigitalZoom = 30.0`.

**Static metadata was incomplete for some cameras.**  Some of the libraries this
provider loads were built for a different board's camera topology, and for the
cameras that do not line up the metadata comes out unsorted or short.
`find_camera_metadata_ro_entry()` binary-searches and silently fails on an
unsorted blob, so `CameraDevice.cpp` scans linearly instead, and repairs streams
missing `ANDROID_SCALER_AVAILABLE_STREAM_CONFIGURATIONS` while
`ANDROID_SCALER_AVAILABLE_MIN_FRAME_DURATIONS` is present.  Both repairs are
recognised by their pathology rather than by camera id, so unaffected devices
keep their metadata untouched.

**One camera's size ladder never ran.**  Camera 4, the 64MP telephoto, ends up
with a four-entry stream configuration table - all of them 1280x3840 - because
its frame-duration tables are mangled.  The rebuild path filters those out by
checking the size fits the sensor's active array, but 1280x3840 fits a 9248x6944
array, so all four survived and `valid < 4` was false, which kept the fallback
ladder from ever running.  The check now also rejects portrait pairs, since
Samsung publishes these tables landscape.  The camera then gets a 33-entry
table with YUV output.  That removes the

    java.lang.IllegalArgumentException: No available output size is found for
    androidx.camera.core.impl.PreviewConfig

failure, but the camera is still not usable.  Switching to it destroys the
camera app's activity and the session never comes up,

    CXCP: Waiting for CameraCaptureSession configuration timed out
    CXCP: Closing Camera 4

so the size table was necessary and not sufficient; the session configuration is
the next thing to look at.

## sm8250-common-voip-tx-port.patch

`AudioPolicyManager::getInputForAttr()` adds `AUDIO_INPUT_FLAG_VOIP_TX` itself
whenever the source is `AUDIO_SOURCE_VOICE_COMMUNICATION` and the format is
linear PCM, and then looks for a mixPort carrying that flag.  The policy here
declared no such port, so the lookup found nothing and the capture was refused:

    AudioRecord.getMinBufferSize failed: -2

which is what broke IMS calls - the stack posts no RTP after the 200 OK and the
call is torn down after 2000 ms.  The HAL side of the path was already complete;
only the policy declaration was missing, and the stock firmware is missing it
too.

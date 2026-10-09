# Cross-repository patches

These changes live outside `device/samsung/y2q` but are required for the device to
work.  Apply them from the root of the corresponding `repo` project:

    cd system/libbase                && git am ../../device/samsung/y2q/patches/libbase-restore-Trim-overload.patch
    cd packages/apps/PhhIms          && git am ../../device/samsung/y2q/patches/phhims-sip-invite-fixes.patch
    cd hardware/qcom-caf/sm8250/audio && git am ../../device/samsung/y2q/patches/audio-hal-adev-set-mode-lock.patch

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
there is no vendor ImsService.  This carries the fixes found while bringing calls
up - see the individual commit in that project.

## audio-hal-adev-set-mode-lock.patch

`adev_set_mode()` in the audio HAL serialises on a lock that the voice call path
already holds, so `MODE_IN_CALL` is issued late and the call has no audio.  The
patch makes the lock a timed one and logs when it is contended.

#
# Copyright (C) 2024-2025 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Overlays
#
# Everything that used to be a DEVICE_PACKAGE_OVERLAYS file now lives in
# rro_overlays/ as a static RRO, so the old
#     DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay $(LOCAL_PATH)/overlay-lineage
# declaration (and both directories) are gone.  The RRO modules themselves are
# listed under the second "# Overlays" block further down, together with the target
# package each one overrides.
#
# Why the change: rro_overlays/ is what the y2s tree uses, and it keeps each
# overlay in its own compiled module with the target package spelled out in its
# AndroidManifest.xml, instead of relying on the directory layout matching the
# upstream source path.

# call the common setup
$(call inherit-product, device/samsung/sm8250-common/common.mk)

# Audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio/audio_platform_info_diff.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_platform_info_diff.xml \
    $(LOCAL_PATH)/configs/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml

# AAPT
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxhdpi
PRODUCT_AAPT_PREBUILT_DPI := xxhdpi xhdpi hdpi

# Display
TARGET_SCREEN_HEIGHT := 3200
TARGET_SCREEN_WIDTH := 1440

# Density mapping per panel resolution
# The S20+ panel cannot do 1440x3200 above 60 Hz, so the build is set up to run
# at 1080x2400 @ 120 Hz by default (see the kernel timing-default change).  The
# framework density has to follow the resolution or the UI scales wrongly:
#   density x dpi scaling -> logical width
#   600 @ 1440 wide = 384 dp     (correct for WQHD+)
#   600 @ 1080 wide = 288 dp     (too narrow - everything would shrink)
#   450 @ 1080 wide = 384 dp     (correct for FHD+)
# This mirrors device/samsung/universal9830-common's approach for y2s, which maps
# 1440x3200 -> 600 and 1080x2400 -> 450 on the same panel family.
# The file name carries this panel's stable display id, read from
# `dumpsys SurfaceFlinger` -> "Display 4630947232161729153".
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/display/display_id_4630947232161729153.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947232161729153.xml

# Camera
$(call soong_config_set,samsungCameraVars,extra_ids,52)


# Init
PRODUCT_PACKAGES += \
    android.hardware.multi-sku.rc \
    init.y2q.rc

$(call soong_config_set,libinit,vendor_init_lib,//$(LOCAL_PATH):libinit_samsung_y2q)

# Bluetooth
# Broadcom BCM4375 over HS-UART - see BoardConfig.mk for why this differs from
# sm8250-common's Qualcomm QTI BT stack.  libbt-vendor is built from the
# hardware/broadcom/libbt source tree, gated by BOARD_HAVE_BLUETOOTH_BCM.
# y2s packages exactly this set, so the userspace side is portable; only the UART
# port in bluetooth/libbt_vndcfg.txt had to be made Qualcomm-specific.
PRODUCT_PACKAGES += \
    android.hardware.bluetooth@1.0-impl:64 \
    android.hardware.bluetooth@1.0-service \
    libbt-vendor:64

# NFC
# NXP SN100U (see vendor.prop for the ro.vendor.nfc.* properties and
# proprietary-files.txt for the blobs).  Service binary is
# nxp.android.hardware.nfc@1.2-service - only ONE NFC service may be installed,
# so android.hardware.nfc-service.nxp (used by r8q) is deliberately NOT here.
# The config-file destinations match stock: /vendor/etc/libnfc-nxp.conf and
# /vendor/etc/nfc/libnfc-nxp_RF.conf.
# libnfc_trim_shim supplies android::base::Trim(std::string const&), which
# Android 14 removed from libbase but the stock NXP blobs still need.  Without
# it the NFC HAL cannot link at runtime and init never registers the service.
# See nfc-shim/trim_shim.cpp.
PRODUCT_PACKAGES += \
    nxp.android.hardware.nfc@1.2-service \
    com.android.nfc_extras \
    Tag \
    libnfc_trim_shim

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/nfc/libnfc-nxp.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nxp.conf \
    $(LOCAL_PATH)/configs/nfc/libnfc-nxp_RF.conf:$(TARGET_COPY_OUT_VENDOR)/etc/nfc/libnfc-nxp_RF.conf \
    $(LOCAL_PATH)/configs/nfc/libnfc-sec-vendor.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-sec-vendor.conf \
    frameworks/native/data/etc/android.hardware.nfc.hcef.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hcef.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/android.hardware.nfc.uicc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.uicc.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/com.nxp.mifare.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/com.nxp.mifare.xml

# Secure Element: source-built nxp/thales services removed (r8q leftovers,
# thales has no y2q blob; device uses prebuilt secure_element@1.1-service)
# PRODUCT_PACKAGES += \
#     android.hardware.secure_element-service.nxp \
#     android.hardware.secure_element-service.thales-sku

# Sensors
PRODUCT_PACKAGES += \
    sensors.samsung

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/sensors/hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/hals.conf

# IMS / VoLTE / VoWiFi
# Samsung's IMS stack is closed source and the Qualcomm IMS blobs from the stock
# firmware are not packaged in this tree, so there is no vendor ImsService at all
# - config_ims_mmtel_package would otherwise resolve to nothing and every call
# would fall back to circuit-switched.  PhhIms supplies a userspace SIP/IMS stack
# implementing android.telephony.ims.ImsService; the overlays that bind it and
# advertise VoLTE/VoWiFi live in overlay/.
# Iwlan and QualifiedNetworksService are bound by package name from the
# framework overlay (config_wlan_data_service_package /
# config_qualified_networks_service_package); without them the WLAN/IMS data path
# never comes up even for VoLTE-only use.
PRODUCT_PACKAGES += \
    PhhIms \
    Iwlan \
    QualifiedNetworksService

# Privileged permissions required by PhhIms (it runs as android.uid.system)
#   privapp-permissions: required because LineageOS sets
#     ro.control_privapp_permissions=enforce unconditionally, so every
#     signature|privileged permission a privileged app requests must be allowlisted.
#   default-permissions: pre-grants RECORD_AUDIO.  It is a *dangerous* permission
#     and the app has no UI, so nothing can grant it at runtime; without this the
#     call connects but the far end cannot hear anything.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/permissions/privapp-permissions-me.phh.ims.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-me.phh.ims.xml \
    $(LOCAL_PATH)/configs/permissions/default-permissions-me.phh.ims.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/default-permissions/default-permissions-me.phh.ims.xml

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    hardware/broadcom/libbt

# UDFPS
$(call soong_config_set,samsungUdfpsVars,udfps_zorder,0x20000000u)
$(call soong_config_set,surfaceflinger,udfps_lib,//hardware/samsung/fingerprint:libudfps_extension.samsung)

# Wi-Fi
PRODUCT_PACKAGES += \
    wifi_brcm.rc \
    WiFiOverlayDevice

# Overlays
#
# Every device resource overlay now lives in rro_overlays/ as a static RRO: each
# directory there carries its own runtime_resource_overlay module plus an
# AndroidManifest.xml naming the target package, and the module name below is what
# pairs the two up.  There is no DEVICE_PACKAGE_OVERLAYS left at all - overlay/ and
# overlay-lineage/ were removed once their last two files (Telephony's IMS
# package, CarrierConfig's vendor.xml) moved in here.
#
# Target packages, for reference when adding another one:
#   FrameworkResOverlayDevice      -> android
#   SettingsOverlayDevice          -> com.android.settings
#   SettingsProviderOverlayDevice  -> com.android.providers.settings
#   SystemUIOverlayDevice          -> com.android.systemui
#   WiFiOverlayDevice              -> com.android.wifi.resources
#   TelephonyOverlayDevice         -> com.android.phone
#   CarrierConfigOverlayDevice     -> com.android.carrierconfig
#   LineageSDKOverlayDevice        -> org.lineageos.platform
#   ApertureOverlayDevice          -> org.lineageos.aperture
#
# TelephonyOverlayDevice is the one that makes IMS possible at all: it sets
# config_ims_mmtel_package=me.phh.ims, without which ImsResolver binds no MmTel
# provider and every call falls back to circuit-switched - which cannot work here,
# because the carrier has no CS network left (ServiceState reports
# voiceRegState=OUT_OF_SERVICE with voiceRadioTech=Unknown while the PS domain is
# registered on LTE).  CarrierConfigOverlayDevice carries the matching
# carrier_volte_available_bool et al.
#
# Note ApertureOverlayDevice targets a product-partition app rather than a system
# one; the rest target system/system_ext/vendor packages.  Static RROs are matched
# to their target by partition, so if Aperture's config stops taking effect, that
# is the thing to look at first.
PRODUCT_PACKAGES += \
    ApertureOverlayDevice \
    CarrierConfigOverlayDevice \
    FrameworkResOverlayDevice \
    LineageSDKOverlayDevice \
    SettingsOverlayDevice \
    SettingsProviderOverlayDevice \
    SystemUIOverlayDevice \
    TelephonyOverlayDevice

# bcmdhd loads its firmware via the standard request_firmware() API, not via
# CONFIG_BCMDHD_FW_PATH: the kernel is built with -DDHD_LINUX_STD_FW_API and
# -DDHD_FW_NAME="bcmdhd_sta.bin" / -DDHD_NVRAM_NAME="nvram.txt"
# (bcmdhd_101_16/Makefile:430-432), which on Android resolves to
# /vendor/firmware/bcmdhd_sta.bin and /vendor/firmware/nvram.txt.
# Stock only ships bcmdhd_sta.bin_b1 (the _b1 is the chip revision) and the
# driver's exact-name lookup does not find it - hence "Wi-Fi listed but never
# comes up".  Ship both under the names the driver actually asks for.
# nvram is not fatal when absent (driver falls back to SROM OTP).
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/wifi/bcmdhd_sta.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/bcmdhd_sta.bin \
    $(LOCAL_PATH)/configs/wifi/nvram.txt:$(TARGET_COPY_OUT_VENDOR)/firmware/nvram.txt

$(call soong_config_set_bool,wpa_supplicant_8,board_wlan_bcmdhd_sae,true)

# Inherit y2q blobs
$(call inherit-product, vendor/samsung/y2q/y2q-vendor.mk)

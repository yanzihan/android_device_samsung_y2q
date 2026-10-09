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

# The panel cannot do 1440x3200 above 60 Hz, so the device runs at 1080x2400 @ 120 Hz
# by default and the density has to follow the resolution: 450 @ 1080 wide gives the
# same 384 dp as 600 @ 1440 wide.  The file name carries this panel's display id.
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
# Broadcom BCM4375 over HS-UART.  libbt-vendor comes from bluetooth/Android.bp as a
# prebuilt of the stock library, not from hardware/broadcom/libbt - see that file.
# The soong_config_set below still selects the build-time config, because
# BOARD_HAVE_BLUETOOTH_BCM builds the 32-bit library.
$(call soong_config_set,brcm_libbt,custom_bt_config,//$(LOCAL_PATH):vnd_y2q.txt)

# bt_rc_name.conf is loaded by RemoteDevices' static initialiser and only has to
# exist; bt_vendor.conf is what the library reads at runtime.  Both go to
# /vendor/etc/bluetooth/.
PRODUCT_PACKAGES += \
    android.hardware.bluetooth@1.0-impl:64 \
    android.hardware.bluetooth@1.0-service \
    libbt-vendor:64 \
    bt_vendor.conf \
    bt_rc_name.conf

# NFC
# NXP SN100U.  Only ONE NFC service may be installed, so the AOSP
# android.hardware.nfc-service.nxp that r8q uses is deliberately absent.
# libnfc_trim_shim supplies android::base::Trim(), which Android 14 removed from
# libbase but the stock NXP blobs still reference; the rc preloads it.  See
# nfc-shim/trim_shim.cpp.
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
# No vendor ImsService is available (Samsung's is closed source and the Qualcomm
# blobs are not packaged), so PhhIms supplies a userspace SIP/IMS stack.  Iwlan and
# QualifiedNetworksService are bound by package name from the framework overlay.
PRODUCT_PACKAGES += \
    PhhIms \
    Iwlan \
    QualifiedNetworksService

# PhhIms runs as android.uid.system, so its privileged permissions must be
# allowlisted (LineageOS enforces ro.control_privapp_permissions).  RECORD_AUDIO is
# a dangerous permission the app has no UI to request, hence default-permissions.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/permissions/privapp-permissions-me.phh.ims.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-me.phh.ims.xml \
    $(LOCAL_PATH)/configs/permissions/default-permissions-me.phh.ims.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/default-permissions/default-permissions-me.phh.ims.xml

# Soong namespaces
# hardware/broadcom/libbt is deliberately NOT listed: it would define libbt-vendor a
# second time, and kati fails with "MODULE.TARGET.SHARED_LIBRARIES.libbt-vendor
# already defined".
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# UDFPS
$(call soong_config_set,samsungUdfpsVars,udfps_zorder,0x20000000u)
$(call soong_config_set,surfaceflinger,udfps_lib,//hardware/samsung/fingerprint:libudfps_extension.samsung)

# Wi-Fi
PRODUCT_PACKAGES += \
    wifi_brcm.rc \
    WiFiOverlayDevice

# Overlays.  Each rro_overlays/ directory is one runtime_resource_overlay module
# whose AndroidManifest.xml names the target package.  DEVICE_PACKAGE_OVERLAYS is no
# longer used at all.
#
#   FrameworkResOverlayDevice      -> android
#   SettingsOverlayDevice          -> com.android.settings
#   SettingsProviderOverlayDevice  -> com.android.providers.settings
#   SystemUIOverlayDevice          -> com.android.systemui
#   WiFiOverlayDevice              -> com.android.wifi.resources
#   TelephonyOverlayDevice         -> com.android.phone
#   CarrierConfigOverlayDevice     -> com.android.carrierconfig
#   LineageSDKOverlayDevice        -> org.lineageos.platform
#   ApertureOverlayDevice          -> org.lineageos.aperture   (product partition)
#
# TelephonyOverlayDevice is what makes IMS possible: it sets
# config_ims_mmtel_package=me.phh.ims.  CarrierConfigOverlayDevice carries the
# matching carrier_volte_available_bool et al.  Static RROs are matched to their
# target by partition, so Aperture is the one to check first if it stops working.
PRODUCT_PACKAGES += \
    ApertureOverlayDevice \
    CarrierConfigOverlayDevice \
    FrameworkResOverlayDevice \
    LineageSDKOverlayDevice \
    SettingsOverlayDevice \
    SettingsProviderOverlayDevice \
    SystemUIOverlayDevice \
    TelephonyOverlayDevice

# bcmdhd loads its firmware through request_firmware(), asking for the exact names
# bcmdhd_sta.bin and nvram.txt.  Stock ships only bcmdhd_sta.bin_b1, so the driver
# never finds it; both are shipped here under the names it asks for.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/wifi/bcmdhd_sta.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/bcmdhd_sta.bin \
    $(LOCAL_PATH)/configs/wifi/nvram.txt:$(TARGET_COPY_OUT_VENDOR)/firmware/nvram.txt

$(call soong_config_set_bool,wpa_supplicant_8,board_wlan_bcmdhd_sae,true)

# Inherit y2q blobs
$(call inherit-product, vendor/samsung/y2q/y2q-vendor.mk)

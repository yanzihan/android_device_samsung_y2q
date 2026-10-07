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

DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay \
    $(LOCAL_PATH)/overlay-lineage

# call the common setup
$(call inherit-product, device/samsung/sm8250-common/common.mk)

# Audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio/audio_platform_info_diff.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_platform_info_diff.xml \
    $(LOCAL_PATH)/configs/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml

# Boot Animation
TARGET_SCREEN_HEIGHT := 3200
TARGET_SCREEN_WIDTH := 1440

# Camera
$(call soong_config_set,samsungCameraVars,extra_ids,52)


# Init
PRODUCT_PACKAGES += \
    android.hardware.multi-sku.rc \
    init.y2q.rc

$(call soong_config_set,libinit,vendor_init_lib,//$(LOCAL_PATH):libinit_samsung_y2q)

# NFC DISABLED for first boot (user call 2026-10-07: no-NFC build first, fix NFC after system boots)
#DEAD-NFC # # NFC
#DEAD-NFC PRODUCT_PACKAGES += \
#DEAD-NFC     android.hardware.nfc-service.nxp \
#DEAD-NFC     nxp.android.hardware.nfc@1.2-service \
#DEAD-NFC     com.android.nfc_extras \
#DEAD-NFC     Tag
#DEAD-NFC 
#DEAD-NFC PRODUCT_COPY_FILES += \
#DEAD-NFC     $(LOCAL_PATH)/configs/nfc/libnfc-sec-vendor.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-sec-vendor.conf \
#DEAD-NFC     $(LOCAL_PATH)/configs/nfc/libnfc-nci-NXP_SN100U.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nci-sn110t.conf \
#DEAD-NFC     $(LOCAL_PATH)/configs/nfc/libnfc-nci-SLSI.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nci-s3fwrn5.conf \
#DEAD-NFC     $(LOCAL_PATH)/configs/nfc/libnfc-nxp.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nxp.conf \
#DEAD-NFC     $(LOCAL_PATH)/configs/nfc/libnfc-nxp_RF.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nxp_RF.conf
#DEAD-NFC 
#DEAD-NFC # Permissions
#DEAD-NFC PRODUCT_COPY_FILES += \
#DEAD-NFC     frameworks/native/data/etc/android.hardware.nfc.hcef.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hcef.xml \
#DEAD-NFC     frameworks/native/data/etc/android.hardware.nfc.hce.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hce.xml \
#DEAD-NFC     frameworks/native/data/etc/android.hardware.nfc.uicc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.uicc.xml \
#DEAD-NFC     frameworks/native/data/etc/android.hardware.nfc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.xml \
#DEAD-NFC     frameworks/native/data/etc/com.nxp.mifare.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/com.nxp.mifare.xml

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

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    hardware/broadcom/libbt

# UDFPS
$(call soong_config_set,samsungUdfpsVars,udfps_zorder,0x20000000u)
$(call soong_config_set,surfaceflinger,udfps_lib,//hardware/samsung/fingerprint:libudfps_extension.samsung)

# Wi-Fi
# Broadcom BCM4375 via bcmdhd (see BoardConfig.mk).  wifi_brcm.rc replaces the
# Qualcomm wifi_qcom.rc inherited from sm8250-common.
# android.hardware.wifi-service / hostapd / wpa_supplicant / wpa_supplicant.conf /
# wifi_sec.rc are already provided AND packaged by sm8250-common - only add what
# is Broadcom/y2q specific here.
PRODUCT_PACKAGES += \
    wifi_brcm.rc \
    WiFiOverlayDevice

# bcmdhd_sta.bin / nvram_net.txt are shipped under the exact names the kernel's
# compile-time CONFIG_BCMDHD_FW_PATH / CONFIG_BCMDHD_NVRAM_PATH look for
# ("/etc/wifi/..." with VENDOR_PATH="/vendor"), which is NOT where the stock
# firmware puts them (vendor/firmware/bcmdhd_sta.bin_b1).  Doing it this way
# avoids having to rebuild the kernel with patched config paths.
#
# The p2p/wpa supplicant overlay confs are deliberately NOT copied from here:
# sm8250-common already copies its own versions to the same destinations, and two
# PRODUCT_COPY_FILES with the same destination but different sources is a build
# error.  Its versions are the generic Qualcomm-oriented ones but harmless for
# bcmdhd; the y2s-tuned copies live in configs/wifi/ for reference.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/wifi/bcmdhd_sta.bin:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/bcmdhd_sta.bin \
    $(LOCAL_PATH)/configs/wifi/nvram_net.txt:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/nvram_net.txt

$(call soong_config_set_bool,wpa_supplicant_8,board_wlan_bcmdhd_sae,true)

# Inherit y2q blobs
$(call inherit-product, vendor/samsung/y2q/y2q-vendor.mk)

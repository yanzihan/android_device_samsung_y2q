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

DEVICE_PATH := device/samsung/y2q

# Partitions
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_CACHEIMAGE_PARTITION_SIZE := 629145600
BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 82694144
BOARD_SUPER_PARTITION_SIZE := 10292822016

include device/samsung/sm8250-common/BoardConfigCommon.mk

# Display
TARGET_SCREEN_DENSITY := 600

# Kernel
TARGET_KERNEL_CONFIG += vendor/samsung/y2q.config
BOARD_NAME := SRPUB26A007

# OTA assert
TARGET_OTA_ASSERT_DEVICE := y2q
TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt

# Properties
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Bluetooth
# y2q uses Broadcom BCM4375 over HS-UART (qupv3_se6_4uart in the kernel dts), the
# same controller family as y2s but on a Qualcomm SoC.  Stock ships
# android.hardware.bluetooth@1.0-service + libbt-vendor.so + bcm4375B1_murata.hcd,
# NOT the Qualcomm QTI BT stack that sm8250-common is configured for
# (android.hardware.bluetooth@1.0-service-qti + htbtfw20.tlv/htnv20.bin).
# BOARD_HAVE_BLUETOOTH_BCM is what makes hardware/broadcom/libbt build
# libbt-vendor; without it the AOSP BT service has no vendor lib to talk to.
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_BCM := true
# NOTE: do NOT reuse y2s's bluetooth/libbt_vndcfg.txt - it sets
# BLUETOOTH_UART_DEVICE_PORT = "/dev/ttySAC1", which is the Exynos UART name.
# Qualcomm's msm_geni_serial registers as /dev/ttyHS*, hence our own file.
BOARD_CUSTOM_BT_CONFIG := $(DEVICE_PATH)/bluetooth/libbt_vndcfg.txt

# Wi-Fi
# y2q uses a Broadcom BCM4375 (Murata module), NOT the Qualcomm QCA6390 that
# device/samsung/sm8250-common (shared with r8q) is configured for.  The stock
# firmware ships bcmdhd_* firmware + vendor/etc/init/wifi_brcm.rc, and the kernel
# is built with CONFIG_BCM4375 / CONFIG_BCM_DHD_WLAN, so the userspace stack has
# to be switched over here.  These use := to override the qcwcn values inherited
# from BoardConfigCommon.mk (which also uses :=), leaving r8q unaffected.
BOARD_WLAN_DEVICE := bcmdhd
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_bcmdhd
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_bcmdhd
WIFI_AVOID_IFACE_RESET_MAC_CHANGE := true
WIFI_FEATURE_HOSTAPD_11AX := true
WIFI_HIDL_FEATURE_AWARE := true
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true

# The inherited qcwcn-only options must be cleared: bcmdhd is a loadable module
# driven by wifi_brcm.rc, it has no /dev/wlan state node and no qca_cld3 driver.
WIFI_DRIVER_DEFAULT :=
WIFI_DRIVER_STATE_CTRL_PARAM :=
WIFI_DRIVER_STATE_OFF :=
WIFI_DRIVER_STATE_ON :=
WPA_SUPPLICANT_VERSION :=

# *_PRIVATE_LIB_EVENT pulls in -DANDROID_LIB_EVENT, which makes wpa_supplicant
# call wpa_driver_nl80211_driver_event().  That symbol is only implemented by the
# Qualcomm driver_cmd_nl80211.c; with BOARD_WLAN_DEVICE := bcmdhd it is undefined
# and wpa_supplicant fails to link:
#   ld.lld: error: undefined symbol: wpa_driver_nl80211_driver_event
# sm8250-common sets the wpa_supplicant one unconditionally (correct for qcwcn),
# and y2s - the other bcmdhd device in this tree - sets neither.
BOARD_WPA_SUPPLICANT_PRIVATE_LIB_EVENT :=
BOARD_HOSTAPD_PRIVATE_LIB_EVENT :=

# UDFPS
TARGET_ADDITIONAL_GRALLOC_10_USAGE_BITS := 0x2000U | 0x400000000LL
TARGET_USES_FOD_ZPOS := true

# VINTF
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/configs/manifest.xml

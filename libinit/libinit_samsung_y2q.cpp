/*
 * Copyright (C) 2021-2024 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <libinit_variant.h>

#include "vendor_init.h"

static const variant_info_t y2qzhx_info = {
    .device = "y2q",
    .model = "SM-G9860",
    .name = "y2qzhx",
    .build_fingerprint = "samsung/y2qzhx/y2q:11/RP1A.200720.012/G9860ZHUCHZE1:user/release-keys",
    .build_desc = "y2qzhx-user 11 RP1A.200720.012 G9860ZHUCHZE1 release-keys"
};

/* TODO: fill with real fingerprints when needed
static const variant_info_t y2qxxx_info = {
    .device = "y2q",
    .model = "SM-G986B",
    .name = "y2qxxx",
    .build_fingerprint = "samsung/y2qxxx/y2q:11/RP1A.200720.012/G986BXXU1AUC3:user/release-keys",
    .build_desc = "y2qxxx-user 11 RP1A.200720.012 G986BXXU1AUC3 release-keys"
};

static const variant_info_t y2qsx_info = {
    .device = "y2q",
    .model = "SM-G986N",
    .name = "y2qsx",
    .build_fingerprint = "samsung/y2qsx/y2q:11/RP1A.200720.012/G986NKSS1AUC3:user/release-keys",
    .build_desc = "y2qsx-user 11 RP1A.200720.012 G986NKSS1AUC3 release-keys"
};
*/

static const std::vector<variant_info_t> variants = {
    y2qzhx_info,
};

void vendor_load_properties() {
    search_variant(variants);
}

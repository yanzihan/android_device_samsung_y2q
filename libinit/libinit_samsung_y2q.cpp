/*
 * Copyright (C) 2021-2024 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <libinit_variant.h>

#include "vendor_init.h"

static const variant_info_t y2qxx_info = {
    .device = "y2q",
    .model = "SM-G780G",
    .name = "y2qxx",
    .build_fingerprint = "samsung/y2qxx/y2q:11/RP1A.200720.012/G780GXXSFEYC1:user/release-keys",
    .build_desc = "y2qxx-user 13 TP1A.220624.014 G780GXXSFEYC1 release-keys"
};

static const variant_info_t y2qxxx_info = {
    .device = "y2q",
    .model = "SM-G781B",
    .name = "y2qxxx",
    .build_fingerprint = "samsung/y2qxxx/y2q:11/RP1A.200720.012/G781BXXSGHYC4:user/release-keys",
    .build_desc = "y2qxxx-user 13 TP1A.220624.014 G781BXXSGHYC4 release-keys"
};

static const variant_info_t y2qksx_info = {
    .device = "y2q",
    .model = "SM-G781N",
    .name = "y2qksx",
    .build_fingerprint = "samsung/y2qksx/y2q:11/RP1A.200720.012/G781NKSSBGYD1:user/release-keys",
    .build_desc = "y2qksx-user 13 TP1A.220624.014 G781NKSSBGYD1 release-keys"
};

static const variant_info_t y2qzcx_info = {
    .device = "y2q",
    .model = "SM-G7810",
    .name = "y2qzcx",
    .build_fingerprint = "samsung/y2qzcx/y2q:11/RP1A.200720.012/ G7810ZHSFHYC1:user/release-keys",
    .build_desc = "y2qzcx-user 13 TP1A.220624.014  G7810ZHSFHYC1 release-keys"
};

static const std::vector<variant_info_t> variants = {
    y2qxx_info,
    y2qxxx_info,
    y2qksx_info,
    y2qzcx_info,
};

void vendor_load_properties() {
    search_variant(variants);
}

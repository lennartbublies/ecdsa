/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

#ifndef __CURVES_TESTCURVE2X9_H
#define __CURVES_TESTCURVE2X9_H

#include "ecctypes.h"
#include "eccmath.h"

static void testcurve9_mod_slow(eccint_t *c, eccint_t *res, const curve_t *curve) {
    eccint_mod(c, curve->q, res, curve);
}

static curve_t testcurve9 = {
    .q = { 0b00000011, 0b00000010 },
    .a = { 0b00000001, 0b00000000 },
    .b = { 0b00000001, 0b00000000 },
    .h = 0x02,


    // This is a random point on the curve, does not necessesarily generate all
    // points. (238,175) = (0b11101110, 0b10101111) = (0xEE, 0xAF)
    .P = {{ 0xEE, 0x00 }, { 0xAF, 0x00 }},

    // This value of n is not necessarily correct for the curve, don't use it
    // for signing.
    .n = { 0b00000110, 0b00000100 },

    .words = 2,
    .m = 9,
    .mod_fast = testcurve9_mod_slow
};
#endif

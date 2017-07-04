/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

#ifndef __ECCMATH_H
#define __ECCMATH_H

#include "ecctypes.h"

#define eccint_add eccint_binary_add
#define eccint_sub eccint_binary_add
#define eccint_mul eccint_shiftnadd_mul
#define eccint_div_mod eccint_binary_sun_div_mod
#define eccint_point_double eccint_book_point_double
#define eccint_point_add eccint_book_point_add
#define eccint_point_mul eccint_binary_doublenadd_mul
//#define eccint_div_mod eccint_binary_book_div_mod
//#define eccint_div_mod eccint_common_div_mod
//#define eccint_inv_mod eccint_common_inv_mod
//#define eccint_point_double eccint_point_double_affine
//#define eccint_point_mul eccint_montgomery_ladder_point_mul

// The squaring speed could be improved by a custom function
#define eccint_square(a, res, curve) eccint_mul((a), (a), res, curve)
#define eccint_square_mod(a, mod, res, curve) eccint_mul_mod((a), (a), mod, res, curve)
#define eccint_even(in) (!(in[0] & 1))

int eccint_degree(const eccint_t *a, const size_t size);
eccint_t eccint_shift_left(const eccint_t *in, eccint_t *res, size_t shift, const size_t size);
eccint_t eccint_shift_right(eccint_t * const in, eccint_t *res, size_t shift, const size_t size);

eccint_t eccint_binary_add(const eccint_t *a, const eccint_t *b, eccint_t *res, const size_t size);

void eccint_general_mod(eccint_t *c, const eccint_t *mod, eccint_t *res, const curve_t *curve);

void eccint_shiftnadd_mul(const eccint_t *a, const eccint_t *b, eccint_t *res, const curve_t *curve);
void eccint_mul_mod(const eccint_t *a, const eccint_t *b, const eccint_t *mod, eccint_t *res, const curve_t *curve);
void eccint_mod(const eccint_t *in, const eccint_t *mod, eccint_t *res, const curve_t *curve);
void eccint_mul_mod_fast(const eccint_t *a, const eccint_t *b, eccint_t *res, const curve_t *curve);

void eccint_binary_sun_div_mod(const eccint_t *y, const eccint_t *x, const eccint_t *mod, eccint_t *res, const curve_t *curve);
void eccint_binary_book_div_mod(const eccint_t *b, const eccint_t *a, const eccint_t *mod, eccint_t *res, const curve_t *curve);
void eccint_inv_mod(const eccint_t *a, const eccint_t *mod, eccint_t *res, const curve_t *curve);

int eccint_point_on_curve(const eccint_point_t *in, const curve_t *curve);

void eccint_book_point_double(const eccint_point_t *p, eccint_point_t *res, const curve_t *curve);
void eccint_book_point_add(const eccint_point_t *p, const eccint_point_t *q, eccint_point_t *res, const curve_t *curve);
void eccint_montgomery_ladder_point_mul(const eccint_t *scalar, const eccint_point_t *p, eccint_point_t *res, const curve_t *curve);
void eccint_binary_doublenadd_mul(const eccint_t *scalar, const eccint_point_t *p, eccint_point_t *res, const curve_t *curve);

#endif

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

#ifndef __ECCMEMORY_H
#define __ECCMEMORY_H

#include "ecctypes.h"

eccint_t eccint_testbit_single(const eccint_t in, const size_t bit);
eccint_t eccint_testbit(const eccint_t *in, const size_t bit);

int eccint_testzero(const eccint_t *in, const size_t size);
int eccint_testinfinite(const eccint_t *in, const size_t size);
int eccint_testnumber(const eccint_t *in, const eccint_t num, const size_t size);
void eccint_setbit(eccint_t *in, const size_t bit, const int val);

int eccint_point_testzero(const eccint_point_t *in, const size_t size);
int eccint_point_testinfinite(const eccint_point_t *in, const size_t size);

void eccint_cpy(eccint_t *dst, const eccint_t *src, const size_t size);
void eccint_cpy_off(eccint_t *dst, const eccint_t *src, const size_t srcsize, const size_t offset);

void eccint_set(eccint_t *dst, const eccint_t elem, const size_t size);
void eccint_set_var(eccint_t *dst, const size_t size, ...);

int eccint_cmp(const eccint_t *a, const eccint_t *b, const size_t size);

int eccint_point_cmp(const eccint_point_t *a, const eccint_point_t *b, const size_t size);
void eccint_point_cpy(eccint_point_t *dst, const eccint_point_t *src, const size_t size);
void eccint_point_set(eccint_point_t *dst, const eccint_t elem, const size_t size);

uint32_t eccint_as_number(const eccint_t *in, const size_t size);
void eccint_from_number(const uint32_t num, eccint_t *res, const size_t size);

#endif

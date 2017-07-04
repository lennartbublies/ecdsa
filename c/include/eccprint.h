/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

#ifndef __ECCPRINT_H
#define __ECCPRINT_H

#include "ecctypes.h"

void ecc_print_binary(const eccint_t a);

void ecc_print(const eccint_t *in, const size_t size);
void ecc_print_n(const eccint_t *in, const size_t size);

void ecc_print_v(const eccint_t *in, const size_t size);
void ecc_print_vn(const eccint_t *in, const size_t size);

void ecc_print_d(const eccint_t *in, const size_t size);
void ecc_print_dn(const eccint_t *in, const size_t size);

void ecc_print_point(const eccint_point_t *in, const size_t size);
void ecc_print_point_n(const eccint_point_t *in, const size_t size);

void ecc_print_point_v(const eccint_point_t *in, const size_t size);
void ecc_print_point_vn(const eccint_point_t *in, const size_t size);

void ecc_print_point_d(const eccint_point_t *in, const size_t size);
void ecc_print_point_dn(const eccint_point_t *in, const size_t size);

void ecc_print_signature(const eccint_signature_t *in, const size_t size);
void ecc_print_signature_n(const eccint_signature_t *in, const size_t size);

#endif

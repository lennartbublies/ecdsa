/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

#ifndef __ECDSA_H
#define __ECDSA_H

#include "ecctypes.h"

void eccint_urand(void *dst, const ssize_t size);

int ecc_keygen(eccint_point_t *publickey, eccint_t *privatekey, const curve_t *curve);
int ecc_validate_publickey(const eccint_point_t *publickey, const curve_t *curve);

void ecc_sign(const eccint_t *privatekey, const eccint_t *hash, eccint_signature_t *signature, const curve_t *curve);
int ecc_verify(const eccint_point_t *publickey, const eccint_t *hash,
               const eccint_signature_t *signature, const curve_t *curve);

#endif

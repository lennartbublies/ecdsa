/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

#ifndef __ECCTYPES_H
#define __ECCTYPES_H

#include <stdint.h>
#include <stdio.h>

#ifndef KEYSIZE
// This should go away in favor of a dynamic memory approach, but it makes some
// of the code very ugly.
#error Need to define KEYSIZE
#endif

#define ECCINT_MIN 0
#define ECCINT_MAX UINT8_MAX

typedef uint8_t eccint_t;
typedef uint16_t ecclong_t;
typedef eccint_t eccint_keyptr_t[KEYSIZE];

typedef struct {
    eccint_t x[KEYSIZE];
    eccint_t y[KEYSIZE];
} eccint_point_t;

typedef struct {
    eccint_t r[KEYSIZE];
    eccint_t s[KEYSIZE];
} eccint_signature_t;

struct _curve_t {
  /* Field order q */
  eccint_t q[KEYSIZE];

  // FR -- Field representation
  // S -- Seed

  /* E is defined by y^2 = x^3 + ax + b over F_q */
  eccint_t a[KEYSIZE];
  eccint_t b[KEYSIZE];

  /* Base Point: Field elements in F_q, defining a finite point P = (x_p, y_p) \in E(F_q) */
  eccint_point_t P;

  /* Order n of P */
  eccint_t n[KEYSIZE+1];

  /* Cofactor h = #E(F_q) / n */
  eccint_t h;

  /* Number of words used, this is KEYSIZE */
  size_t words;

  /* Bits in curve, e.g. 163 in sect163k1 */
  size_t m;

  void (*mod_fast)(eccint_t *, eccint_t *, const struct _curve_t *);
};

typedef struct _curve_t curve_t;

void eccint_set(eccint_t *dst, const eccint_t elem, const size_t size);
void eccint_cpy(eccint_t *dst, const eccint_t *src, const size_t size);
uint32_t eccint_as_number(const eccint_t *in, const size_t size);

#endif

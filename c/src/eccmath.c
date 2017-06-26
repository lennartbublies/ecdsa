/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

#include <stdlib.h>

#include "ecctypes.h"
#include "eccmath.h"
#include "eccmemory.h"
#include "eccprint.h"

// Determine the degree of the number passed. The degree is the highest bit set
// in the number
int eccint_degree(const eccint_t *a, const size_t size) {
    static const eccint_t bitpos[8] = { 0, 5, 1, 6, 4, 3, 2, 7 };

    ssize_t i;
    for (i = size - 1; i >= 0 && a[i] == 0; i--) {}

    if (i < 0) {
        return -1;
    }
    eccint_t n = a[i];
    n |= (n >>  1);
    n |= (n >>  2);
    n |= (n >>  4);
    n *= 0x1du;
    n >>= 5;
    return bitpos[n] + (8 * (i));
}

// Shift the number left by |shift|, filling with zeros where needed
eccint_t eccint_shift_left(const eccint_t *in, eccint_t *res, size_t shift, const size_t size) {
    eccint_t epsilon = 0;

    if (shift == 0 && res != in) {
        eccint_cpy(res, in, size);
        return 0;
    }

    int wshift = shift / 8;
    if (wshift > 0) {

        for (ssize_t i = size - 1; i >= wshift; i--) {
            res[i] = in[i-wshift];
        }
        for (ssize_t i = wshift - 1; i >= 0; i--) {
            res[i] = 0;
        }

        shift = shift % 8;
    }

    for (size_t i = 0; i < size; i++) {
    //for (ssize_t i = size - 1; i >= 0; i--) {
        eccint_t tmp = in[i];
        res[i] = (tmp << shift) | epsilon;
        epsilon = tmp >> (8 - shift);
    }

    return epsilon;
}

// Shift the number right by |shift|, filling with zeros where needed
eccint_t eccint_shift_right(eccint_t * const in, eccint_t *res, size_t shift, const size_t size) {
    eccint_t epsilon = 0;

    for (ssize_t i = size - 1; i >= 0; i--) {
        eccint_t tmp = in[i];
        res[i] = (tmp >> shift) | epsilon;
        epsilon = tmp << (8 - shift);
    }
    return epsilon;
}

// Binary add the numbers a and b. This equates to a XOR operation on the numbers
eccint_t eccint_binary_add(const eccint_t *a, const eccint_t *b, eccint_t *res, const size_t size) {
    for (size_t i = 0; i < size; i++) {
        res[i] = a[i] ^ b[i];
    }
    return 0;
}

// Binary multiply with shift and add. Note that |res| must be double the size of a and b.
void eccint_shiftnadd_mul(const eccint_t *a, const eccint_t *b, eccint_t *res, const curve_t *curve) {
    // Book Algorithm 2.33. Better for hardware where shift operation can be
    // performed in parallel. Less desirable for software where shifting means
    // many memory accesses.

    // maximum degree is 2m - 2, e.g. 2 * 163 - 2 = 324
    size_t doublewords = 2 * curve->words;

    eccint_t bcpy[doublewords];

    eccint_t rz[curve->words];
    eccint_setbit(rz, curve->m, 0);

    eccint_cpy(rz, curve->q, curve->words);

    eccint_set(res, 0, doublewords);
    eccint_set(bcpy, 0, doublewords);
    eccint_cpy(bcpy, b, curve->words);

    // if a_0 = 0 then c <- b, else c <- 0
    if (eccint_testbit(a, 0)) {
        eccint_cpy(res, bcpy, curve->words);
    }

    for (size_t bit = 1; bit < curve->m; bit++) {
        // b <- b * z mod f(z) : left-shift of the vector-representation of  b(z)
        eccint_shift_left(bcpy, bcpy, 1, doublewords);

        // This can be optimized by doing mod directly when bit m - 1 is set,
        // by adding curve->q

        if (eccint_testbit(a, bit)) {
            // c <- c + b
            eccint_add(res, bcpy, res, doublewords);

        }
    }
}

// General modulo function for polynomials. The polynomial in c is double word
// size and will be reduced using the polynomial in mod. The result is single
// word size.
void eccint_general_mod(eccint_t *c, const eccint_t *mod, eccint_t *res, const curve_t *curve) {
    // Algorithm 2.40
    eccint_t table[2 * curve->m][2 * curve->words];
    int md = eccint_degree(mod, curve->words);
    for (size_t i = 0; i < 2 * curve->m; i++) {
        eccint_set(table[i], 0, 2 * curve->words);
        eccint_cpy(table[i], mod, curve->words);

        eccint_shift_left(table[i], table[i], i, 2 * curve->words);
    }

    for (size_t i = 2 * curve->m - 2; i >= curve->m; i--) {
        if (eccint_testbit(c, i)) {
            eccint_add(c, table[i - md], c, 2 * curve->words);
        }
    }

    eccint_cpy(res, c, curve->words);
}

// Multiply, applying modulus inbetwen. a, b and res are all standard word length
void eccint_mul_mod(const eccint_t *a, const eccint_t *b, const eccint_t *mod, eccint_t *res, const curve_t *curve) {
    eccint_t product[2 * curve->words];
    eccint_mul(a, b, product, curve);
    eccint_general_mod(product, mod, res, curve);

}

// Run the modulo on a standard word size input. This is useful for further reducing a number
void eccint_mod(const eccint_t *in, const eccint_t *mod, eccint_t *res, const curve_t *curve) {

    eccint_t indbl[curve->words * 2];

    eccint_set(indbl, 0, curve->words * 2);
    eccint_cpy(indbl, in, curve->words);

    eccint_general_mod(indbl, mod, res, curve);
}

// Fast reduction using the curve's fast reduction function
void eccint_mul_mod_fast(const eccint_t *a, const eccint_t *b, eccint_t *res, const curve_t *curve) {
    eccint_t product[2 * curve->words - 1];
    eccint_mul(a, b, product, curve);
    curve->mod_fast(product, res, curve);
}

// Division, by a modulo specified. res = y / x
// Uses the algorith from Sun's paper
void eccint_binary_sun_div_mod(const eccint_t *y, const eccint_t *x, const eccint_t *mod, eccint_t *res, const curve_t *curve) {
    if (eccint_testzero(x, curve->words)) {
        printf("#div0");
        abort();
        return;
    }
    if (eccint_testzero(y, curve->words)) {
        eccint_set(res, 0, curve->words);
        return;
    }

    eccint_t A[curve->words];
    eccint_t B[curve->words];
    eccint_t U[curve->words];
    eccint_t V[curve->words];


    eccint_cpy(A, x, curve->words);
    eccint_cpy(B, mod, curve->words);
    eccint_cpy(U, y, curve->words);
    eccint_set(V, 0, curve->words);

    int cmp;

    while ((cmp = eccint_cmp(A, B, curve->words)) != 0) {
        if (eccint_even(A)) {
            eccint_shift_right(A, A, 1, curve->words);

            if (!eccint_even(U)) {
                eccint_add(U, mod, U, curve->words);
            }
            eccint_shift_right(U, U, 1, curve->words);
        } else if (eccint_even(B)) {
            eccint_shift_right(B, B, 1, curve->words);

            if (!eccint_even(V)) {
                eccint_add(V, mod, V, curve->words);
            }
            eccint_shift_right(V, V, 1, curve->words);
        } else if (cmp > 0) {
            eccint_add(A, B, A, curve->words);
            eccint_shift_right(A, A, 1, curve->words);
            eccint_add(U, V, U, curve->words);

            if (!eccint_even(U)) {
                eccint_add(U, mod, U, curve->words);
            }
            eccint_shift_right(U, U, 1, curve->words);
        } else {
            eccint_add(B, A, B, curve->words);
            eccint_shift_right(B, B, 1, curve->words);
            eccint_add(V, U, V, curve->words);

            if (!eccint_even(V)) {
                eccint_add(V, mod, V, curve->words);
            }
            eccint_shift_right(V, V, 1, curve->words);
        }
    }

    eccint_cpy(res, U, curve->words);
}

// Division, by a modulo specified. res = y / x
// Uses the algorithm from the ecc book
void eccint_binary_book_div_mod(const eccint_t *b, const eccint_t *a, const eccint_t *mod, eccint_t *res, const curve_t *curve) {
    if (eccint_testzero(a, curve->words)) {
        eccint_cpy(res, a, curve->words);
        return;
    }
    if (eccint_testzero(b, curve->words)) {
        eccint_set(res, 0, curve->words);
        return;
    }


    // Algorithm 2.48, with division
    eccint_t _u[curve->words];
    eccint_t _v[curve->words];
    eccint_t _g1[curve->words];
    eccint_t _g2[curve->words];

    eccint_t *u = _u;
    eccint_t *v = _v;
    eccint_t *g1 = _g1;
    eccint_t *g2 = _g2;



    eccint_cpy(u, a, curve->words);
    eccint_cpy(v, mod, curve->words);

    eccint_cpy(g1, b, curve->words);
    eccint_set(g2, 0, curve->words);

    while (eccint_testnumber(u, 1, curve->words) != 1) {
        int j = eccint_degree(u, curve->words) - eccint_degree(v, curve->words);

        if (j < 0) {
            eccint_t *tmp = v;
            v = u;
            u = tmp;

            tmp = g2;
            g2 = g1;
            g1 = tmp;

            j = -j;
        }

        eccint_t t1[curve->words];

        // u <- u + z^j * v
        eccint_shift_left(v, t1, j, curve->words);
        eccint_add(u, t1, u, curve->words);

        // g1 <- g1 + z^j * g2
        eccint_shift_left(g2, t1, j, curve->words);
        eccint_add(g1, t1, g1, curve->words);

    }

    eccint_cpy(res, g1, curve->words);
}

// Inversion of a number, which equals divison 1 / in
void eccint_inv_mod(const eccint_t *a, const eccint_t *mod, eccint_t *res, const curve_t *curve) {
    eccint_t g1[curve->words];
    eccint_set(g1, 0, curve->words);
    g1[0] = 1;

    eccint_div_mod(g1, a, mod, res, curve);
}

// Checks if a point is on the curve
int eccint_point_on_curve(const eccint_point_t *in, const curve_t *curve) {
    if (eccint_point_testinfinite(in, curve->words)) {
        return 1;
    }
    // Verify that Q satifies the elliptic curve equation
    // E_1: y^2 + xy = x^3 + ax^2 + b (a = 1, b = 1)
    eccint_t tl[curve->words];
    eccint_t tr[curve->words];
    eccint_t t1[curve->words];

    // x^3 + ax^2 + b
    eccint_square_mod(in->x, curve->q, tr, curve); // x^2
    eccint_mul_mod(tr, in->x, curve->q, t1, curve); // x^3
    eccint_mul_mod(tr, curve->a, curve->q, tr, curve); // ax^2
    eccint_add(tr, t1, tr, curve->words); // x^3 + ax^2

    eccint_add(tr, curve->b, tr, curve->words); // x^3 + ax^2 + b

    // y^2 + xy
    eccint_square_mod(in->y, curve->q, tl, curve); // y^2
    eccint_mul_mod(in->x, in->y, curve->q, t1, curve); // x * y
    eccint_add(tl, t1, tl, curve->words); // y^2 + xy

    return (eccint_cmp(tl, tr, curve->words) == 0);
}


// Doubles an ECC point into res
void eccint_book_point_double(const eccint_point_t *p, eccint_point_t *res, const curve_t *curve) {
    if (eccint_point_testinfinite(p, curve->words)) {
        eccint_set(res->x, ECCINT_MAX, curve->words);
        eccint_set(res->y, ECCINT_MAX, curve->words);
        return;

    }
    if (eccint_testzero(p->x, curve->words)) {
        eccint_set(res->x, ECCINT_MAX, curve->words);
        eccint_set(res->y, ECCINT_MAX, curve->words);
        return;
    }

    // Section 3.1, page 81
    // For x^2 + xy = x^3 + ax^2 + b in E/F_{2^m}
    eccint_t lambda[curve->words];
    eccint_t t1[curve->words];

    eccint_t x3[curve->words];
    eccint_t y3[curve->words];

    // l = x_1 + (y_1 / x_1)
    eccint_div_mod(p->y, p->x, curve->q, lambda, curve);
    eccint_add(lambda, p->x, lambda, curve->words);

    // x_3 = l^2 + l + a
    eccint_square_mod(lambda, curve->q, x3, curve);

    eccint_add(x3, lambda, x3, curve->words);
    eccint_add(x3, curve->a, x3, curve->words);

    // y_3 = {x_1}^2 + l * x_3 + x_3
    // y_3 = {x_1}^2 +   t1    + x_3
    eccint_mul_mod(lambda, x3, curve->q, t1, curve);
    eccint_square_mod(p->x, curve->q, y3, curve);
    eccint_add(y3, t1, y3, curve->words);
    eccint_add(y3, x3, y3, curve->words);

    eccint_cpy(res->x, x3, curve->words);
    eccint_cpy(res->y, y3, curve->words);
}

// Adds two ECC points on the curve
void eccint_book_point_add(const eccint_point_t *p, const eccint_point_t *q, eccint_point_t *res, const curve_t *curve) {
    if (eccint_point_testinfinite(p, curve->words)) {
        eccint_point_cpy(res, q, curve->words);
        return;
    }
    if (eccint_point_testinfinite(q, curve->words)) {
        eccint_point_cpy(res, p, curve->words);
        return;
    }

    if (eccint_cmp(p->x, q->x, curve->words) == 0) {
        if (eccint_cmp(p->y, q->y, curve->words) != 0) {
            eccint_point_set(res, ECCINT_MAX, curve->words);
        } else {
            eccint_book_point_double(p, res, curve);
        }
        return;
    }

    // Section 3.1, page 81
    // For x^2 + xy = x^3 + ax^2 + b in E/F_{2^m}
    eccint_t lambda[curve->words];
    eccint_t tx[curve->words];
    eccint_t ty[curve->words];

    eccint_t x3[curve->words];
    eccint_t y3[curve->words];

    // l = (y1 + y2) / (x1 + x2)
    // l = (  ty   ) / (  tx   )
    eccint_add(p->x, q->x, tx, curve->words);
    eccint_add(p->y, q->y, ty, curve->words);

    //eccint_div_mod(ty, tx, curve->q, lambda, curve);
    eccint_t t2[curve->words];
    eccint_inv_mod(tx, curve->q, t2, curve);
    eccint_mul_mod(ty, t2, curve->q, lambda, curve);


    // x_3 = l^2 + l + x1 + x2 + a
    eccint_square_mod(lambda, curve->q, x3, curve);
    eccint_add(x3, lambda, x3, curve->words);
    eccint_add(x3, p->x, x3, curve->words);
    eccint_add(x3, q->x, x3, curve->words);
    eccint_add(x3, curve->a, x3, curve->words);

    // y_3 = l * ( x1 + x3) + x3 + y1
    // y_3 = l * (    tx  ) + x3 + y1
    eccint_add(p->x, x3, tx, curve->words);

    eccint_mul_mod(lambda, tx, curve->q, y3, curve);
    eccint_add(y3, x3, y3, curve->words);
    eccint_add(y3, p->y, y3, curve->words);

    eccint_cpy(res->x, x3, curve->words);
    eccint_cpy(res->y, y3, curve->words);
}

// Multiplication using the montgomery ladder
void eccint_montgomery_ladder_point_mul(const eccint_t *scalar, const eccint_point_t *p, eccint_point_t *res, const curve_t *curve) {
    if (eccint_testzero(scalar, curve->words) || eccint_testzero(p->x, curve->words)) {
        eccint_set(res->x, 0, curve->words);
        eccint_set(res->y, 0, curve->words);
    }

    eccint_point_t r0, r1;
    eccint_point_set(&r0, 0, curve->words);
    eccint_point_cpy(&r1, p, curve->words);

    for (ssize_t i = curve->m; i >= 0; i--) {
        if (eccint_testbit(scalar, i)) {
            eccint_point_add(&r0, &r1, &r0, curve);
            eccint_point_double(&r1, &r1, curve);
        } else {
            eccint_point_add(&r0, &r1, &r1, curve);
            eccint_point_double(&r0, &r0, curve);
        }
    }

    eccint_point_cpy(res, &r0, curve->words);
}

// Multiplication using double-and-add
void eccint_binary_doublenadd_mul(const eccint_t *scalar, const eccint_point_t *p, eccint_point_t *res, const curve_t *curve) {
    // Algorithm 3.27
    eccint_point_t r0;

    // Q <- \infty
    eccint_point_set(&r0, ECCINT_MAX, curve->words);

    // For i from t - 1 downto 0 do
    for (ssize_t i = eccint_degree(scalar, curve->words) - 1; i >= 0; i--) {
        // Q <- 2Q
        eccint_point_double(&r0, &r0, curve);

        // if k_i = 1 then
        if (eccint_testbit(scalar, i)) {
            // Q <- Q + P
            eccint_point_add(&r0, p, &r0, curve);
        }
    }

    eccint_point_cpy(res, &r0, curve->words);
}

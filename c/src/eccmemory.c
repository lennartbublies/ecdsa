/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

#include "ecctypes.h"
#include "eccmemory.h"

// --- test functions ---

// Checks a single bit to see if it is set
eccint_t eccint_testbit_single(const eccint_t in, const size_t bit) {
    return (in & (1 << bit));
}

// Checks a bit in a full eccint number if a bit is set
eccint_t eccint_testbit(const eccint_t *in, const size_t bit) {
    return eccint_testbit_single(in[bit / 8], bit % 8);
}

// Sets a specific bit in the eccint number
void eccint_setbit(eccint_t *in, const size_t bit, const int val) {
    if (val) {
        in[bit / 8] |= 1 << (bit % 8);
    } else {
        in[bit / 8] &= ~(1 << (bit % 8));
    }
}

// Checks if the eccint number is zero
int eccint_testzero(const eccint_t *in, const size_t size) {
    for (size_t i = 0; i < size; i++) {
        if (in[i] != 0) {
            return 0;
        }
    }
    return 1;
}

// Checks if the eccint number is infinite
int eccint_testinfinite(const eccint_t *in, const size_t size) {
    for (size_t i = 0; i < size; i++) {
        if (in[i] != ECCINT_MAX) {
            return 0;
        }
    }
    return 1;
}

// Checks if the eccint point is zero
int eccint_point_testzero(const eccint_point_t *in, const size_t size) {
    return eccint_testzero(in->x, size) && eccint_testzero(in->y, size);
}

// Checks if the eccint point is infinite
int eccint_point_testinfinite(const eccint_point_t *in, const size_t size) {
    return eccint_testinfinite(in->x, size) && eccint_testinfinite(in->y, size);
}

// Checks the eccint number against specific number (in the first word)
int eccint_testnumber(const eccint_t *in, const eccint_t num, const size_t size) {
    return eccint_testzero(in + 1, size - 1) && in[0] == num;
}

// --- memory functions

// Copy eccint values
void eccint_cpy(eccint_t *dst, const eccint_t *src, const size_t size) {
    if (dst != src) {
        memcpy(dst, src, size * sizeof(eccint_t));
    }
}

// Copy eccint values with offset
void eccint_cpy_off(eccint_t *dst, const eccint_t *src, const size_t srcsize, const size_t offset) {
    for (size_t i = 0; i < srcsize; i++) {
        dst[i+offset] = src[i];
    }
}

// Sets an eccint number to a specific elemnt in each word
void eccint_set(eccint_t *dst, const eccint_t elem, const size_t size) {
    for (size_t i = 0; i < size; i++) {
        dst[i] = elem;
    }
}

/**
 * Set from named args. Note the order is big endian for readability, but is
 * saved in little endian. Make sure count is the full size of the multiword.
 */
void eccint_set_var(eccint_t *dst, const size_t size, ...) {
    va_list elems;

    va_start(elems, size);

    for (size_t i = 0; i < size; i++) {
        dst[size - i - 1] = va_arg(elems, int);
    }

    va_end(elems);
}

// Compares eccint numbers, with result -1 0 or 1
int eccint_cmp(const eccint_t *a, const eccint_t *b, const size_t size) {
    for (ssize_t i = size - 1; i >= 0; i--) {
        if (a[i] > b[i]) {
            return 1;
        } else if (a[i] < b[i]) {
            return -1;
        }
    }
    return 0;
}

// Compares eccint points, the same way
int eccint_point_cmp(const eccint_point_t *a, const eccint_point_t *b, const size_t size) {
    return !(eccint_cmp(a->x, b->x, size) == 0 && eccint_cmp(a->y, b->y, size) == 0);
}

// Copies eccint points from src to dst
void eccint_point_cpy(eccint_point_t *dst, const eccint_point_t *src, const size_t size) {
    eccint_cpy(dst->x, src->x, size);
    eccint_cpy(dst->y, src->y, size);
}

// Sets all point elements to a specific value
void eccint_point_set(eccint_point_t *dst, const eccint_t elem, const size_t size) {
    eccint_set(dst->x, elem, size);
    eccint_set(dst->y, elem, size);
}

// Returns a uint32 number from the eccint number, usually for debugging
uint32_t eccint_as_number(const eccint_t *in, const size_t size) {
    union {
        uint32_t u32;
        uint8_t u8[4];
    } u;

    if (size > 4) {
        abort();
    }
    u.u32 = 0;
    eccint_cpy(u.u8, in, size);
    return u.u32;
}

// Converts a uint32 number into an eccint number
void eccint_from_number(const uint32_t num, eccint_t *res, const size_t size) {
    union {
        uint32_t u32;
        uint8_t u8[4];
    } u;

    u.u32 = num;

    eccint_set(res, 0, size);
    eccint_cpy(res, u.u8, size < 4 ? size : 4);
}

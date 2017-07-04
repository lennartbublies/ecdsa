/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

#include <stdlib.h>
#include <stdio.h>

#define CUTEST_NO_FORK
#define CUTEST_PADDING 50
//#define PRINT_SWAP

#include "ecctypes.h"
#include "eccprint.h"
#include "eccmemory.h"
#include "ecdsa.h"

#include "cutest.h"
#include "curves/sect163k1.h"
#include "curves/testcurve2x9.h"
#include "sha256.h"

#ifdef TEST_VERBOSE
#include "tables.h"
#endif

void test_eccint_testzero(void) {
    eccint_t in[3];
    in[0] = 0;
    in[1] = 0;
    in[2] = 0;

    TEST_CHECK(eccint_testzero(in, 3));
    in[1] = 1;
    TEST_CHECK(!eccint_testzero(in, 3));
}

void test_eccint_testbit(void) {
    eccint_t in[2];
    in[0] = 0b10000001;
    in[1] = 0b01111110;

    TEST_CHECK(eccint_testbit_single(in[0], 0));
    TEST_CHECK(!eccint_testbit_single(in[0], 1));
    TEST_CHECK(!eccint_testbit_single(in[0], 2));
    TEST_CHECK(!eccint_testbit_single(in[0], 3));
    TEST_CHECK(!eccint_testbit_single(in[0], 4));
    TEST_CHECK(!eccint_testbit_single(in[0], 5));
    TEST_CHECK(!eccint_testbit_single(in[0], 6));
    TEST_CHECK(eccint_testbit_single(in[0], 7));

    TEST_CHECK(!eccint_testbit(in, 8));
    TEST_CHECK(eccint_testbit(in, 9));
    TEST_CHECK(eccint_testbit(in, 10));
    TEST_CHECK(eccint_testbit(in, 11));
    TEST_CHECK(eccint_testbit(in, 12));
    TEST_CHECK(eccint_testbit(in, 13));
    TEST_CHECK(eccint_testbit(in, 14));
    TEST_CHECK(!eccint_testbit(in, 15));
}

void test_eccint_memory(void) {
    eccint_t a[3] = { 0, 1, 2 };
    eccint_t b[3] = { 0, 1, 2 };

    // eccint_cmp
    TEST_CHECK(eccint_cmp(a, b, 3) == 0);
    b[1] = 0; b[2] = 0;
    TEST_CHECK(eccint_cmp(a, b, 3) == 1);
    b[1] = 4; b[2] = 4;
    TEST_CHECK(eccint_cmp(a, b, 3) == -1);

    // eccint_cpy
    TEST_CHECK(eccint_cmp(a, b, 3) != 0);
    eccint_cpy(b, a, 3);
    TEST_CHECK(eccint_cmp(a, b, 3) == 0);

    // eccint_set
    eccint_set(b, 4, 3);
    TEST_CHECK(b[0] == 4);
    TEST_CHECK(b[1] == 4);
    TEST_CHECK(b[2] == 4);

    // eccint_from_number
    a[0] = a[1] = a[2] = 0;
    b[1] = b[2] = 0; b[0] = 0b10000000;
    eccint_from_number(128, a, 3);
    TEST_CHECK(eccint_cmp(a, b, 3) == 0);


    // eccint_set_var
    eccint_set_var(a, 3, 0b00000100, 0b00000010, 0b00000001);
    TEST_CHECK(a[0] == 1);
    TEST_CHECK(a[1] == 2);
    TEST_CHECK(a[2] == 4);

    // eccint_cpy_off
    eccint_set_var(a, 3, 0b00000100, 0b00000010, 0b00000001);
    eccint_set_var(b, 3, 0b00000000, 0b00000000, 0b10000000);
    eccint_cpy_off(a, b, 3, 0);
    TEST_CHECK(eccint_cmp(a, b, 0) == 0);
}

void test_eccint_cpy_offset(void) {
    eccint_t src[3];
    eccint_t dst[6];
    eccint_t exp[6];
    eccint_set_var(src, 3, 0xFF, 0xFF, 0xFF);

    eccint_set_var(dst, 6, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01);
    eccint_set_var(exp, 6, 0x20, 0x10, 0x08, 0xFF, 0xFF, 0xFF);
    eccint_cpy_off(dst, src, 3, 0);
    TEST_CHECK(eccint_cmp(dst, exp, 6) == 0);

    eccint_set_var(dst, 6, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01);
    eccint_set_var(exp, 6, 0x20, 0x10, 0xFF, 0xFF, 0xFF, 0x01);
    eccint_cpy_off(dst, src, 3, 1);
    TEST_CHECK(eccint_cmp(dst, exp, 6) == 0);

    eccint_set_var(dst, 6, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01);
    eccint_set_var(exp, 6, 0x20, 0xFF, 0xFF, 0xFF, 0x02, 0x01);
    eccint_cpy_off(dst, src, 3, 2);
    TEST_CHECK(eccint_cmp(dst, exp, 6) == 0);

    eccint_set_var(dst, 6, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01);
    eccint_set_var(exp, 6, 0xFF, 0xFF, 0xFF, 0x04, 0x02, 0x01);
    eccint_cpy_off(dst, src, 3, 3);
    TEST_CHECK(eccint_cmp(dst, exp, 6) == 0);
}

void test_eccint_point_memory(void) {
    // eccint_point_cmp
    eccint_point_t p = { { 1, 2, 3 }, { 4, 5, 6 } };
    eccint_point_t q = { { 1, 2, 3 }, { 4, 5, 6 } };

    TEST_CHECK(eccint_point_cmp(&p, &q, 3) == 0);

    p.x[1] = 4;
    TEST_CHECK(eccint_point_cmp(&p, &q, 3) != 0);
}

void test_eccint_shift(void) {
    eccint_t in00[3] = { 0b00000001, 0b00000011, 0b00000111 };
    eccint_t inl1[3] = { 0b00000010, 0b00000110, 0b00001110 };
    eccint_t inl2[3] = { 0b00000100, 0b00001100, 0b00011100 };

    eccint_t cur[3] = { 0b00000001, 0b00000011, 0b00000111 };
    eccint_t cur2[3];

    eccint_shift_left(cur, cur, 1, 3);
    TEST_CHECK(eccint_cmp(cur, inl1, 3) == 0);

    eccint_shift_left(cur, cur2, 1, 3);
    TEST_CHECK(eccint_cmp(cur, inl1, 3) == 0);
    TEST_CHECK(eccint_cmp(cur2, inl2, 3) == 0);

    eccint_shift_right(cur2, cur, 2, 3);
    TEST_CHECK(eccint_cmp(cur, in00, 3) == 0);
}

void test_eccint_shift_overflow(void) {
    eccint_t original[3] = { 0b10000000, 0b00000000, 0b00000000 };
    eccint_t expected[3] = { 0b00000000, 0b00000001, 0b00000000 };

    eccint_t overflow[3];
    eccint_cpy(overflow, original, 3);

    eccint_shift_left(overflow, overflow, 1, 3);
    TEST_CHECK(eccint_cmp(overflow, expected, 3) == 0);

    eccint_shift_right(overflow, overflow, 1, 3);
    TEST_CHECK(eccint_cmp(overflow, original, 3) == 0);
}


void test_eccint_addsub(void) {
    const eccint_t a[2] =      { 0b00000001, 0b10000111 };
    const eccint_t b[2] =      { 0b00000010, 0b10000101 };
    const eccint_t exor[2]  =  { 0b00000011, 0b00000010 };

    eccint_t res[2];

    // add in binary
    eccint_add(a, b, res, testcurve9.words);
    TEST_CHECK(eccint_cmp(res, exor, testcurve9.words) == 0);

    // subtract in binary, in place
    // ADD is the same as SUB in binary fields (uses XOR)
    eccint_sub(res, b, res, testcurve9.words);
    TEST_CHECK(eccint_cmp(res, a, testcurve9.words) == 0);
}

void test_eccint_mul(void) {
    eccint_t a[2] =        { 0b00001010, 0b00000000, }; // 2
    eccint_t b[2] =        { 0b00000110, 0b00000000, }; // 3
    eccint_t expected[4] = { 0b00111100, 0b00000000,
                             0b00000000, 0b00000000, }; // 6
    eccint_t res[4];

    eccint_set(res, 0, 2 * testcurve9.words);
    eccint_mul(a, b, res, &testcurve9);
    TEST_CHECK(eccint_cmp(res, expected, 2 * testcurve9.words) == 0);
}

void test_eccint_mul_overflow(void) {
    eccint_t a[2] =        { 0b00001111, 0b00000001 }; // 271
    eccint_t b[2] =        { 0b11110000, 0b00000001 }; // 495
    eccint_t expected[4] = { 0b01010000, 0b11111010,
                             0b00000001, 0b00000000 }; // 129616
    eccint_t res[4];

    eccint_set(res, 0, 2 * testcurve9.words);
    eccint_mul(a, b, res, &testcurve9);
    TEST_CHECK(eccint_cmp(res, expected, 2 * testcurve9.words) == 0);
}

void test_eccint_div_inv_mod(void) {
    eccint_t in[2] = { 0b00000010, 0b00000000 }; // 2
    eccint_t expected[2] = { 0b00000001, 0b00000001 };

    eccint_t res[2];
    eccint_t res2[2];

    eccint_inv_mod(in, testcurve9.q, res, &testcurve9);
    TEST_CHECK(eccint_cmp(res, expected, testcurve9.words) == 0);

    eccint_mul_mod(in, res, testcurve9.q, res2, &testcurve9);
    TEST_CHECK(eccint_testnumber(res2, 1, testcurve9.words));
}

void test_eccint_general_mod(void) {
    eccint_t exp[2] = { 0b01010100, 0b00000001  }; // 340
    eccint_t mres[4] = { 0b10101010, 0b01010100, 0b00000001, 0b00000000 };
    eccint_t res[2];

    eccint_general_mod(mres, testcurve9.q, res, &testcurve9);
    TEST_CHECK(eccint_cmp(exp, res, testcurve9.words) == 0);
}

void test_eccint_mul_mod(void) {
    eccint_t res[6];

    eccint_t a[2] = { 0b11111111, 0b00000001 }; // 511
    eccint_t b[2] = { 0b11111110, 0b00000001 }; // 510
    eccint_t exp[2] = { 0b01010100, 0b00000001  }; // 340

    eccint_set(res, 0, testcurve9.words * 2);
    eccint_mul(a, b, res, &testcurve9);

    eccint_mul_mod(a, b, testcurve9.q, res, &testcurve9);
    TEST_CHECK(eccint_cmp(exp, res, testcurve9.words) == 0);
}

void test_eccint_point_addition(void) {
    // Values match rye.js solution
    eccint_point_t INFTY    = { { ECCINT_MAX, ECCINT_MAX }, { ECCINT_MAX, ECCINT_MAX } };
    eccint_point_t P        = { { 0b00000010, 0b00000000 }, { 0b00001111, 0b00000000 } };
    eccint_point_t P2       = { { 0b00000010, 0b00000000 }, { 0b00001111, 0b00001111 } };
    eccint_point_t Q        = { { 0b00001100, 0b00000000 }, { 0b00001100, 0b00000000 } };
    eccint_point_t expected = { { 0b01101001, 0b00000001 }, { 0b01001111, 0b00000001 } };
    eccint_point_t res;

    eccint_point_add(&P, &Q, &res, &testcurve9);
    TEST_CHECK(eccint_point_cmp(&res, &expected, testcurve9.words) == 0);

    eccint_point_add(&P, &INFTY, &res, &testcurve9);
    TEST_CHECK(eccint_point_cmp(&res, &P, testcurve9.words) == 0);

    eccint_point_add(&INFTY, &Q, &res, &testcurve9);
    TEST_CHECK(eccint_point_cmp(&res, &Q, testcurve9.words) == 0);

    eccint_point_add(&P, &P2, &res, &testcurve9);
    TEST_CHECK(eccint_point_testinfinite(&res, testcurve9.words));
}

void test_eccint_point_doubling(void) {
    // Values match rye.js solution
    eccint_point_t ZERO     = { { 0b00000000, 0b00000000 }, { 0b00000000, 0b00000000 } };
    eccint_point_t INFTY    = { { ECCINT_MAX, ECCINT_MAX }, { ECCINT_MAX, ECCINT_MAX } };
    eccint_point_t in       = { { 0b00000010, 0b00000000 }, { 0b00001111, 0b00000000 } };
    eccint_point_t expected = { { 0b10010101, 0b00000000 }, { 0b00011000, 0b00000001 } };
    eccint_point_t res;

    eccint_point_double(&in, &res, &testcurve9);
    TEST_CHECK(eccint_point_cmp(&res, &expected, testcurve9.words) == 0);

    eccint_point_double(&INFTY, &res, &testcurve9);
    TEST_CHECK(eccint_point_testinfinite(&res, testcurve9.words));

    eccint_point_double(&ZERO, &res, &testcurve9);
    TEST_CHECK(eccint_point_testinfinite(&res, testcurve9.words));
}

void test_eccint_point_multiply(void) {
    eccint_point_t expected = { { 0b11010011, 0b00000000 }, { 0b00100111, 0b00000001 } };
    eccint_t k[testcurve9.words];
    eccint_point_t in, res;

    eccint_from_number(511, k, testcurve9.words);
    eccint_from_number(511, in.x, testcurve9.words);
    eccint_from_number(447, in.y, testcurve9.words);

    eccint_point_mul(k, &in, &res, &testcurve9);
    TEST_CHECK(eccint_point_cmp(&res, &expected, testcurve9.words) == 0);
}

void test_ecc_curve_sanity(void) {
    TEST_CHECK(ecc_validate_publickey(&sect163k1.P, &sect163k1));
    TEST_CHECK(eccint_testbit(sect163k1.q, 163));
    TEST_CHECK(eccint_testbit(sect163k1.q, 7));
    TEST_CHECK(eccint_testbit(sect163k1.q, 6));
    TEST_CHECK(eccint_testbit(sect163k1.q, 3));
    TEST_CHECK(eccint_testbit(sect163k1.q, 0));

    
    TEST_CHECK(ecc_validate_publickey(&testcurve9.P, &testcurve9));
    TEST_CHECK(eccint_testbit(testcurve9.q, 9));
    TEST_CHECK(eccint_testbit(testcurve9.q, 1));
    TEST_CHECK(eccint_testbit(testcurve9.q, 0));
}

#ifdef TEST_VERBOSE
void test_eccint_point_on_curve_verbose(void) {
    for (size_t i = 0; i < 517; i++) {
        eccint_point_t p;
        eccint_cpy(p.x, gf_2x9_curve_point[i][0], testcurve9.words);
        eccint_cpy(p.y, gf_2x9_curve_point[i][1], testcurve9.words);
        int ok = eccint_point_on_curve(&p, &testcurve9);
        TEST_CHECK_(ok, "Point (%u %u, %u %u) should be on curve",
                    gf_2x9_curve_point[i][0][0], gf_2x9_curve_point[i][0][1],
                    gf_2x9_curve_point[i][1][0], gf_2x9_curve_point[i][1][1]);
    }
}

void test_eccint_point_double_on_curve_verbose(void) {
    for (size_t i = 1; i < 517; i++) {
        eccint_point_t p, p2;
        eccint_cpy(p.x, gf_2x9_curve_point[i][0], testcurve9.words);
        eccint_cpy(p.y, gf_2x9_curve_point[i][1], testcurve9.words);

        eccint_point_double(&p, &p2, &testcurve9);
        if (eccint_testzero(p.x, testcurve9.words)) {
            TEST_CHECK_(eccint_point_testinfinite(&p2, testcurve9.words), "expected 2 * (%u,%u) = infinity but got (%u,%u)",
                        eccint_as_number(p.x, testcurve9.words),
                        eccint_as_number(p.y, testcurve9.words),
                        eccint_as_number(p.x, testcurve9.words),
                        eccint_as_number(p.y, testcurve9.words));
        } else {
            TEST_CHECK_(eccint_point_on_curve(&p2, &testcurve9), " 2 * (%u,%u) = (%u,%u) should be on curve",
                        eccint_as_number(p.x, testcurve9.words),
                        eccint_as_number(p.y, testcurve9.words),
                        eccint_as_number(p2.x, testcurve9.words),
                        eccint_as_number(p2.y, testcurve9.words));
        }
    }
}

void test_eccint_point_add_on_curve_verbose(void) {
    for (size_t _p = 1; _p < 517; _p++) {
        for (size_t _q = 1; _q < 517; _q++) {
            eccint_point_t p, q, r;
            eccint_cpy(p.x, gf_2x9_curve_point[_p][0], testcurve9.words);
            eccint_cpy(p.y, gf_2x9_curve_point[_p][1], testcurve9.words);
            eccint_cpy(q.x, gf_2x9_curve_point[_q][0], testcurve9.words);
            eccint_cpy(q.y, gf_2x9_curve_point[_q][1], testcurve9.words);

            eccint_point_add(&p, &q, &r, &testcurve9);

            TEST_CHECK_(eccint_point_on_curve(&r, &testcurve9), " (%u,%u) + (%u,%u) = (%u,%u) should be on curve",
                        eccint_as_number(p.x, testcurve9.words),
                        eccint_as_number(p.y, testcurve9.words),
                        eccint_as_number(q.x, testcurve9.words),
                        eccint_as_number(q.y, testcurve9.words),
                        eccint_as_number(r.x, testcurve9.words),
                        eccint_as_number(r.y, testcurve9.words));
        }
    }
}

void test_eccint_point_multiply_on_curve_verbose(void) {
    for (size_t i = 1; i < 517; i++) {
        for (uint32_t num = 0, max = 1 << testcurve9.m; num < max; num++) {
            eccint_point_t p, r;
            eccint_t k[testcurve9.words];

            eccint_cpy(p.x, gf_2x9_curve_point[i][0], testcurve9.words);
            eccint_cpy(p.y, gf_2x9_curve_point[i][1], testcurve9.words);
            eccint_from_number(num, k, testcurve9.words);

            eccint_point_mul(k, &p, &r, &testcurve9);

            TEST_CHECK_(eccint_point_on_curve(&r, &testcurve9), " %d * (%u,%u) = (%u,%u) should be on curve",
                        num,
                        eccint_as_number(p.x, testcurve9.words),
                        eccint_as_number(p.y, testcurve9.words),
                        eccint_as_number(r.x, testcurve9.words),
                        eccint_as_number(r.y, testcurve9.words));
        }
    }
}

void test_eccint_addsub_verbose(void) {
    const int elems = 1 << testcurve9.m;
    for (uint32_t a = 0; a < elems; a++) {
        for (uint32_t b = 0; b < elems; b++) {

            eccint_t ea[testcurve9.words];
            eccint_t eb[testcurve9.words];
            eccint_t res[testcurve9.words];
            eccint_from_number(a, ea, testcurve9.words);
            eccint_from_number(b, eb, testcurve9.words);

            eccint_add(ea, eb, res, testcurve9.words);
            TEST_CHECK_(eccint_cmp(res, gf_2x9_add[a][b], testcurve9.words) == 0,
                        "%u + %u = %u (res) vs %u (table)", a, b,
                        eccint_as_number(res, testcurve9.words),
                        eccint_as_number(gf_2x9_add[a][b], testcurve9.words));
        }
    }
}

void test_eccint_mul_verbose(void) {
    const int elems = 1 << testcurve9.m;
    for (uint32_t a = 0; a < elems; a++) {
        for (uint32_t b = 0; b < elems; b++) {

            eccint_t ea[testcurve9.words];
            eccint_t eb[testcurve9.words];
            eccint_t res[2 * testcurve9.words];
            eccint_from_number(a, ea, testcurve9.words);
            eccint_from_number(b, eb, testcurve9.words);

            eccint_mul(ea, eb, res, &testcurve9);

            TEST_CHECK_(eccint_cmp(res, gf_2x9_mul[a][b], 2 * testcurve9.words) == 0,
                        "%u * %u = %u (res) vs %u (table)", a, b,
                        eccint_as_number(res, 2 * testcurve9.words),
                        eccint_as_number(gf_2x9_mul[a][b], 2 * testcurve9.words));

        }
    }
}

void test_eccint_mul_mod_verbose(void) {
    const int elems = 1 << testcurve9.m;
    for (uint32_t a = 0; a < elems; a++) {
        for (uint32_t b = 0; b < elems; b++) {

            eccint_t ea[testcurve9.words];
            eccint_t eb[testcurve9.words];
            eccint_t res[testcurve9.words];
            eccint_from_number(a, ea, testcurve9.words);
            eccint_from_number(b, eb, testcurve9.words);

            eccint_mul_mod(ea, eb, testcurve9.q, res, &testcurve9);

            TEST_CHECK_(eccint_cmp(res, gf_2x9_mul_mod[a][b], testcurve9.words) == 0,
                        "%u * %u mod q = %u (res) vs %u (table)", a, b,
                        eccint_as_number(res, testcurve9.words),
                        eccint_as_number(gf_2x9_mul_mod[a][b], testcurve9.words));
        }
    }
}

void test_eccint_inv_mod_verbose(void) {
    const int elems = 1 << testcurve9.m;
    for (uint32_t in = 1; in < elems; in++) {

            eccint_t ein[testcurve9.words];
            eccint_t res[testcurve9.words];
            eccint_from_number(in, ein, testcurve9.words);

            eccint_inv_mod(ein, testcurve9.q, res, &testcurve9);

            TEST_CHECK_(eccint_cmp(res, gf_2x9_inv_mod[in], testcurve9.words) == 0,
                        "%u^-1 = %u (res) vs %u (table)", in,
                        eccint_as_number(res, testcurve9.words),
                        eccint_as_number(gf_2x9_inv_mod[in], testcurve9.words));
    }
}

void test_ecc_tables_sanity(void) {
    // check the add table, since XOR is pretty simple. Given this test passes
    // and they are generated in the same way I will assume the rye
    // implementation is correct and the other tables are correct just the
    // same.
    union {
        uint16_t u16;
        uint8_t u8[2];
    } gftable;

    const int elems = 512; // GF(2^9)
    for (uint16_t a = 0; a < elems; a++) {
        for (uint16_t b = 0; b < elems; b++) {
            // add is xor in binary
            uint16_t res = a ^ b;

            gftable.u8[0] = gf_2x9_add[a][b][0];
            gftable.u8[1] = gf_2x9_add[a][b][1];

            TEST_CHECK_(res == gftable.u16, "%d + %d = %d (res) vs %d (table)", a, b, res, gftable.u16);
        }
    }
}
#endif

void test_ecc_make_key(void) {
    const curve_t *curve = &sect163k1;

    eccint_point_t publickey;
    eccint_t privatekey[curve->words];

    int ok = ecc_keygen(&publickey, privatekey, curve);
    TEST_CHECK(ok == 1);

    ok = ecc_validate_publickey(&publickey, curve);
    TEST_CHECK(ok == 1);
}


void test_ecc_sign_verify(void) {
    curve_t *curve = &testcurve9;
    eccint_point_t publickey;
    eccint_t privatekey[curve->words];
    eccint_t hash[curve->words];
    eccint_signature_t signature;

    eccint_urand(hash, curve->words);
    eccint_mod(hash, curve->n, hash, curve);


    int ok = ecc_keygen(&publickey, privatekey, curve);
    TEST_CHECK(ok == 1);
    ok = ecc_validate_publickey(&publickey, curve);
    TEST_CHECK(ok == 1);

    ecc_sign(privatekey, hash, &signature, curve);
    TEST_CHECK(eccint_cmp(signature.r, curve->n, curve->words) < 0);

    ok = ecc_verify(&publickey, hash, &signature, curve);
    TEST_CHECK(ok == 1);
}

void test_ecc_hash_verify(void) {
    curve_t *curve = &testcurve9;
    eccint_point_t publickey;
    eccint_t privatekey[curve->words];
    eccint_t hash[curve->words];
    eccint_signature_t signature;
    SHA256_CTX hashctx;
    unsigned char hashbytes[SHA256_BLOCK_SIZE];
    const char message[] = "The quick brown fox jumps over the lazy dog";
    const eccint_t expected[] = { 0xd7, 0xa8, 0xfb, 0xb3, 0x07, 0xd7, 0x80, 0x94, 0x69, 0xca, 0x9a, 0xbc, 0xb0, 0x08, 0x2e, 0x4f, 0x8d, 0x56, 0x51, 0xe4, 0x6d, 0x3c, 0xdb, 0x76, 0x2d, 0x02, 0xd0, 0xbf, 0x37, 0xc9, 0xe5, 0x92 };

    eccint_urand(hash, curve->words);
    eccint_mod(hash, curve->n, hash, curve);

    sha256_init(&hashctx);
    sha256_update(&hashctx, (unsigned char *) message, strlen(message));
    sha256_final(&hashctx, hashbytes);
    eccint_cpy(hash, hashbytes, curve->words);
    eccint_mod(hash, curve->n, hash, curve);

    TEST_CHECK(eccint_cmp(hashbytes, expected, 32) == 0);

    int ok = ecc_keygen(&publickey, privatekey, curve);
    TEST_CHECK(ok == 1);
    ok = ecc_validate_publickey(&publickey, curve);
    TEST_CHECK(ok == 1);

    ecc_sign(privatekey, hash, &signature, curve);
    TEST_CHECK(eccint_cmp(signature.r, curve->n, curve->words) < 0);

    ok = ecc_verify(&publickey, hash, &signature, curve);
    TEST_CHECK(ok == 1);
}

TEST_LIST = {
    { "eccint_testzero", test_eccint_testzero },
    { "eccint_testbit", test_eccint_testbit },

    { "eccint_memory", test_eccint_memory },
    { "eccint_cpy_offset", test_eccint_cpy_offset },
    { "eccint_point_memory", test_eccint_point_memory },
    { "eccint_shift", test_eccint_shift },
    { "eccint_shift_overflow", test_eccint_shift_overflow },

    { "eccint_addsub", test_eccint_addsub },
    { "eccint_mul", test_eccint_mul },
    { "eccint_mul_overflow", test_eccint_mul_overflow },

    { "eccint_div_inv_mod", test_eccint_div_inv_mod },
    { "eccint_general_mod", test_eccint_general_mod },
    { "eccint_mul_mod", test_eccint_mul_mod },

    { "eccint_point_addition", test_eccint_point_addition },
    { "eccint_point_doubling", test_eccint_point_doubling },
    { "eccint_point_multiply", test_eccint_point_multiply },

    { "ecc_make_key", test_ecc_make_key },
    { "ecc_curve_sanity", test_ecc_curve_sanity },
    { "ecc_sign_verify", test_ecc_sign_verify },
    { "ecc_hash_verify", test_ecc_hash_verify },

#ifdef TEST_VERBOSE
    { "ecc_tables_sanity", test_ecc_tables_sanity },
    { "eccint_addsub_verbose", test_eccint_addsub_verbose },
    { "eccint_mul_verbose", test_eccint_mul_verbose },
    { "eccint_mul_mod_verbose", test_eccint_mul_mod_verbose },
    { "eccint_inv_mod_verbose", test_eccint_inv_mod_verbose },
    { "eccint_point_on_curve_verbose", test_eccint_point_on_curve_verbose },
    { "eccint_point_double_on_curve_verbose", test_eccint_point_double_on_curve_verbose },
    { "eccint_point_add_on_curve_verbose", test_eccint_point_add_on_curve_verbose },
    { "eccint_point_multiply_on_curve_verbose", test_eccint_point_multiply_on_curve_verbose },
#endif
    { 0 }
};

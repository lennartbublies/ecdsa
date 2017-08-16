/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

#include "eccprint.h"

// Various debug printing functions. Enjoy!

void ecc_print_binary(const eccint_t a) {
    for(eccint_t i=0x80;i!=0;i>>=1) printf("%c",(a&i)?'1':'0');
}

void ecc_print(const eccint_t *in, const size_t size) {
    ssize_t i;
#ifdef PRINT_SWAP
    printf("{ ");
    for (i = 0; size > 1 && i < size - 1;i++) {
        printf("0b");
        ecc_print_binary(in[i]);
        printf(", ");
    }
    printf("0b");
    ecc_print_binary(in[size - 1]);
    printf(" }");
#else
    for (i = size - 1; i >= 1; i--) {
        ecc_print_binary(in[i]);
        //printf(" ");
        //printf("%02X", in[i]);
    }
    ecc_print_binary(in[i]);
    //printf("%02X", in[i]);
#endif
}

void ecc_print_n(const eccint_t *in, const size_t size) {
    ecc_print(in, size);
    printf("\n");
}

void ecc_print_v(const eccint_t *in, const size_t size) {
    ecc_print(in, size);
    printf(" = %u", eccint_as_number(in, size));
}

void ecc_print_vn(const eccint_t *in, const size_t size) {
    ecc_print(in, size);
    printf(" = %u\n", eccint_as_number(in, size));
}

void ecc_print_d(const eccint_t *in, const size_t size) {
    printf("%u", eccint_as_number(in, size));
}

void ecc_print_dn(const eccint_t *in, const size_t size) {
    ecc_print_d(in, size);
    printf("\n");
}

void ecc_print_point(const eccint_point_t *in, const size_t size) {
    printf("x = ");
    ecc_print(in->x, size);
    printf("\ny = ");
    ecc_print(in->y, size);
}

void ecc_print_point_v(const eccint_point_t *in, const size_t size) {
    printf("x = ");
    ecc_print_v(in->x, size);
    printf("\ny = ");
    ecc_print_v(in->y, size);
}

void ecc_print_point_d(const eccint_point_t *in, const size_t size) {
    printf("(%u/%u)", eccint_as_number(in->x, size), eccint_as_number(in->y, size));
}

void ecc_print_point_dn(const eccint_point_t *in, const size_t size) {
    ecc_print_point_d(in, size);
    printf("\n");
}

void ecc_print_point_n(const eccint_point_t *in, const size_t size) {
    ecc_print_point(in, size);
    printf("\n");
}

void ecc_print_point_vn(const eccint_point_t *in, const size_t size) {
    ecc_print_point_v(in, size);
    printf("\n");
}

void ecc_print_signature(const eccint_signature_t *in, const size_t size) {
    printf("r = ");
    ecc_print(in->r, size);
    printf("\ns = ");
    ecc_print(in->s, size);
}

void ecc_print_signature_n(const eccint_signature_t *in, const size_t size) {
    ecc_print_signature(in, size);
    printf("\n");
}

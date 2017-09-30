/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>

#include "ecctypes.h"
#include "eccprint.h"
#include "eccmemory.h"
#include "eccmath.h"


// --- ecsda static k ---

/*static eccint_t KK[21] = {
          //0x03,0x35,0x5B,0xF8,0x3C,0x49,0x7F,0x92,0x2F,0xFA,0xEC,0x53,0xC7,0x31,0x5B,0x34,0x8F,0xAF,0xB4,0xDA,0x2F
          //0x00,0xCD,0x06,0x20,0x32,0x60,0xEE,0xE9,0x54,0x93,0x51,0xBD,0x29,0x73,0x3E,0x7D,0x1E,0x2E,0xD4,0x9D,0x88
          //0x2F,0xDA,0xB4,0xAF,0x8F,0x34,0x5B,0x31,0xC7,0x53,0xEC,0xFA,0x2F,0x92,0x7F,0x49,0x3C,0xF8,0x5B,0x35,0x03 // swapped
          //0x88,0x9D,0xD4,0x2E,0x1E,0x7D,0x3E,0x73,0x29,0xBD,0x51,0x93,0x54,0xE9,0xEE,0x60,0x32,0x20,0x06,0xCD,0x00 // swapped
          0x05,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 // swapped
};*/ // K=163

static eccint_t KK[2] = {
          0b01101001, 0b00000000
}; // K=9

// --- ecsda funcs ---

// Generate random bytes into dst
void eccint_urand(void *dst, const ssize_t size) {
    int randfd = open("/dev/urandom", O_RDONLY);
    if (read(randfd, dst, size) != size) {
        printf("Failed to get random bytes.\n");
        abort();
    }
}

// Generate ECC keypair
int ecc_keygen(eccint_point_t *publickey, eccint_t *privatekey, const curve_t *curve) {

    // Generate a random key candidate
    eccint_urand(privatekey, curve->words);

    // Book Algorithm 4.24
    eccint_mod(privatekey, curve->n, privatekey, curve);

    if (eccint_testzero(privatekey, curve->words)) {
        return 0;
    }

    // Compute Q = d * P <=> publickey = privatekey * D(P)
    eccint_point_mul(privatekey, &curve->P, publickey, curve);
    return 1;
}

// Validate the public key to see if it is correct
int ecc_validate_publickey(const eccint_point_t *publickey, const curve_t *curve) {
    // Algorithm 4.25

    // Verify that Q != \infty
    if (eccint_testnumber(publickey->x, ECCINT_MAX, curve->words) || eccint_testnumber(publickey->y, ECCINT_MAX, curve->words)) {
        return 0;
    }

    // Verify that xQ and yQ are elements of F_{2^m}, in the interval [0, q-1]
    if (eccint_point_testzero(publickey, curve->words)) {
        return 0;
    }
    if (eccint_cmp(publickey->x, curve->q, curve->words) >= 0 || eccint_cmp(publickey->y, curve->q, curve->words) >= 0) {
        return 0;
    }

    //eccint_point_t nQ;
    //eccint_point_mul(curve->n, publickey, &nQ, curve);
    //if (!eccint_point_testinfinite(&nQ, curve->words)) {
    //    return 0;
    //}

    return eccint_point_on_curve(publickey, curve);
}

// Sign a hash using the passed private key
void ecc_sign_verbose(const eccint_t *privatekey, const eccint_t *hash, eccint_signature_t *signature, const curve_t *curve, eccint_t verbose) {
    // Algorithm 4.29
    //eccint_t k[curve->words];
    eccint_t * k = KK;
    eccint_t t1[curve->words];
    eccint_t t2[curve->words];
    eccint_t t3[curve->words];
    eccint_point_t point;

    do {
        do {
            // Select k \in [1, n - 1]
            // -- ENABLE THIS CODE FOR RANDOM K --
            //do {
            //    eccint_urand(k, curve->words);
            //} while (eccint_testzero(k, curve->words));
            //eccint_mod(k, curve->n, k, curve);

            // Compute kP = (x_1, y_1) and convert x_1 to integer
            eccint_point_mul(k, &curve->P, &point, curve);
             
            // Compute r = x_1 mod n
            eccint_mod(point.x, curve->n, signature->r, curve);

            // If r=0 then goto step 1.
        } while (eccint_testzero(signature->r, curve->words));

        // e = hash = H(m)
        // Compute s = k^(-1) * (e + d * r) mod n
        //         s =         ((e +  t1  ) / k) mod n
        
        // t1 = d * r
        // WRONG? I think we have to calculate this: (da*r mod q) mod n
        // But this code calculates this: da*r mod n
        //eccint_mul_mod(privatekey, signature->r, curve->n, t2, curve);
        eccint_mul_mod(privatekey, signature->r, curve->q, t2, curve);
        eccint_mod(t2, curve->n, t2, curve);

        eccint_add(hash, t2, t1, curve->words); // t1 = e + d * r
        // WRONG? Maybe same issue like before
        //eccint_div_mod(t1, k, curve->n, signature->s, curve);
        eccint_div_mod(t1, k, curve->q, t3, curve);
        eccint_mod(t3, curve->n, signature->s, curve);

        if (verbose) {
            printf("# SIGN: da = \n    ");
            ecc_print_n(privatekey, curve->words);
            printf("# SIGN: hash = \n    ");
            ecc_print_n(hash, curve->words);
            printf("# SIGN: k = \n    ");
            ecc_print_n(k, curve->words);
            printf("# SIGN: kP = \n");
            ecc_print_point_n(&point, curve->words);
            printf("# SIGN: r =  (kPx)\n    ");
            ecc_print_n(signature->r, curve->words);
            printf("# SIGN: d * kPx  = \n    ");
            ecc_print_n(t2, curve->words);
            printf("# SIGN: e + d * kPx  = \n    ");
            ecc_print_n(t1, curve->words);
            printf("# SIGN: s =  ((e + d * kPx)/k)\n    ");
            ecc_print_n(signature->s, curve->words);
            printf("\n");
        }

        // If s=0 then goto step 1.
    } while (eccint_testzero(signature->s, curve->words));
}
void ecc_sign(const eccint_t *privatekey, const eccint_t *hash, eccint_signature_t *signature, const curve_t *curve) {
    ecc_sign_verbose(privatekey, hash, signature, curve, 0);
}

// Verify the signature of the hash based on the public key
int ecc_verify_verbose(const eccint_point_t *publickey, const eccint_t *hash, const eccint_signature_t *signature, const curve_t *curve, eccint_t verbose) {
    // Algorithm 4.30
    eccint_t v[curve->words];
    eccint_t w[curve->words];
    eccint_t u1[curve->words];
    eccint_t u2[curve->words];
    eccint_point_t X, X1, X2;

    const eccint_t *s = signature->s;
    const eccint_t *r = signature->r;

    // Verify that r and s are integers in the interval [1, n − 1].
    if (eccint_testzero(r, curve->words) || eccint_testzero(r, curve->words)) {
        return 0;
    }
    if (eccint_cmp(r, curve->n, curve->words) >= 0) {
        return 0;
    }
    if (eccint_cmp(s, curve->n, curve->words) >= 0) {
        return 0;
    }

    // Compute w = s^(-1) mod n
    // WRONG? Maybe same issue like above
    //eccint_inv_mod(signature->s, curve->n, w, curve);
    eccint_inv_mod(signature->s, curve->q, w, curve);
    eccint_mod(w, curve->n, w, curve);

    // Compute u_1 = e * w mod n
    // WRONG? Maybe same issue like above
    //eccint_mul_mod(hash, w, curve->n, u1, curve);
    eccint_mul_mod(hash, w, curve->q, u1, curve);
    eccint_mod(u1, curve->n, u1, curve);
    
    // ...and u_2 = r * w mod n
    // WRONG? Maybe same issue like above
    //eccint_mul_mod(signature->r, w, curve->n, u2, curve);
    eccint_mul_mod(signature->r, w, curve->q, u2, curve);
    eccint_mod(u2, curve->n, u2, curve);

    // Compute X = u_1 * P + u_2 * Q
    //         X =    X1   +     X2
    // TODO could use Shamir's trick
    eccint_point_mul(u1, &curve->P, &X1, curve);
    eccint_point_mul(u2, publickey, &X2, curve);
    eccint_point_add(&X1, &X2, &X, curve);

    // If X = \infty then reject
    if (eccint_point_testinfinite(&X, curve->words)) {
        return 0;
    }

    // Convert the x-coordinate of X to an integer
    // Compute v = x_1 mod n
    eccint_mod(X.x, curve->n, v, curve);

    if (verbose) {
        printf("# VERIFY: hash = \n    ");
        ecc_print_n(hash, curve->words);
        printf("# VERIFY: signature\n");
        ecc_print_signature_n(signature, curve->words);
        printf("# VERIFY: w = \n    ");
        ecc_print_n(w, curve->words);
        printf("# VERIFY: u_1 = \n    ");
        ecc_print_n(u1, curve->words);
        printf("# VERIFY: u_2 = \n    ");
        ecc_print_n(u2, curve->words);
        printf("# VERIFY: x_1 =  (u_1 * P)\n");
        ecc_print_point_n(&X1, curve->words);
        printf("# VERIFY: x_2 =  (u_2 * Q)\n");
        ecc_print_point_n(&X2, curve->words);
        printf("# VERIFY: x =  (u_1 * P + u_2 * Q)\n");
        ecc_print_point_n(&X, curve->words);
        printf("\n");
    }

    // If v = r then accept
    //return (eccint_cmp(v, r, curve->words) != 0);    //WRONG!!!
    return (eccint_cmp(v, r, curve->words) == 0);
}

int ecc_verify(const eccint_point_t *publickey, const eccint_t *hash, const eccint_signature_t *signature, const curve_t *curve) {
    return ecc_verify_verbose(publickey, hash, signature, curve, 0);
}

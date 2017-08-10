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


// --- ecsda funcs ---

static eccint_t KK[21] = {
          0x92,0xA3,0x8B,0x73,0xEA,0x4F,0x2B,0xB9,0x8F,0xD2,0xC1,0x18,0xE4,0x34,0x2A,0x5A,0xC9,0x30,0xD3,0xE0,0x05
};

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
    eccint_point_t point;

    do {
        do {
            // Select k \in [1, n - 1]
            //do {
            //    eccint_urand(k, curve->words);
            //} while (eccint_testzero(k, curve->words));

            //eccint_mod(k, curve->n, k, curve);

            // Compute kP = (x_1, y_1) and convert x_1 to integer
            //eccint_point_mul(k, &curve->P, &point, curve);
            eccint_point_mul(k, &curve->P, &point, curve);

            // Compute r = x_1 mod n
            eccint_mod(point.x, curve->n, signature->r, curve);

            // If r=0 then goto step 1.
        } while (eccint_testzero(signature->r, curve->words));

        // e = hash = H(m)
        // Compute s = k^(-1) * (e + d * r) mod n
        //         s =         ((e +  t1  ) / k) mod n

        // t1 = d * r
        eccint_mul_mod(privatekey, signature->r, curve->n, t1, curve);

        eccint_add(hash, t1, t1, curve->words); // t1 = e + d * r
        eccint_div_mod(t1, k, curve->n, signature->s, curve);

        printf("# k = \n    ");
        ecc_print_n(k, curve->words);
        printf("# kP = \n");
        ecc_print_point_n(&point, curve->words);
        printf("# r =  (kPx)\n    ");
        ecc_print_n(signature->r, curve->words);
        printf("# e + d * kPx  = \n    ");
        ecc_print_n(t1, curve->words);
        printf("# s =  ((e + d * kPx)/k)\n    ");
        ecc_print_n(signature->s, curve->words);

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
    eccint_inv_mod(signature->s, curve->n, w, curve);

    // Compute u_1 = e * w mod n
    eccint_mul_mod(hash, w, curve->n, u1, curve);
    // ...and u_2 = r * w mod n
    eccint_mul_mod(signature->r, w, curve->n, u2, curve);

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

    // If v = r then accept
    return (eccint_cmp(v, r, curve->words) != 0);
}

int ecc_verify(const eccint_point_t *publickey, const eccint_t *hash, const eccint_signature_t *signature, const curve_t *curve) {
    return ecc_verify_verbose(publickey, hash, signature, curve, 0);
}

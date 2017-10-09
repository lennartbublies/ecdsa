#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#include "ecctypes.h"
#include "eccprint.h"
#include "eccmemory.h"
#include "ecdsa.h"

#include "curves/sect163k1.h"
//#include "curves/testcurve2x9.h"
#include "sha256.h"

// Enable DEBUG
static eccint_t DEBUG = 1;

// Number of measurments
static eccint_t MEASUREMENTS = 1;

// K=163
static eccint_t dA[21] = {
          0xCA,0x87,0x3B,0xF2,0xFC,0x81,0x2B,0x82,0x5E,0xA2,0x9B,0xC0,0xAF,0x78,0x96,0x71,0x70,0xBA,0x78,0x4E,0x05 // swapped
};
static eccint_point_t QA =  { 
    .x = {0x17,0xB9,0xB9,0x79,0x1E,0x06,0x7A,0x8B,0x61,0xED,0x4F,0x58,0x3D,0x53,0xA6,0x85,0xF9,0xE0,0xB2,0x80,0x06}, // swapped
    .y = {0xBA,0x94,0x8C,0xE3,0xC4,0xCE,0xA5,0xDB,0xE9,0x84,0x48,0x23,0x4F,0xE9,0xA8,0x2B,0x95,0x3A,0x12,0x9D,0x03} // swapped
};

static eccint_t dB[21] = {
          0xA7,0x15,0x46,0x34,0x24,0xF5,0x71,0x6B,0x3F,0xAB,0x1E,0x9C,0x8A,0xCE,0xDC,0x30,0xB9,0x8C,0xA3,0x08,0x00 // swapped
};
static eccint_point_t QB =  { 
    .x = {0x16,0x32,0x49,0x22,0x2A,0x60,0xA6,0x12,0xE8,0x69,0x95,0x3B,0xA6,0x1D,0x85,0xB7,0x14,0x53,0x84,0xD4,0x00}, // swapped
    .y = {0xB0,0x4B,0x72,0xA3,0x79,0x9C,0x07,0xE4,0x5F,0xA1,0xAF,0xB1,0x2F,0xDD,0x81,0x29,0x2A,0x71,0x5B,0x0D,0x00} // swapped
};

static eccint_t testhash[21] = {
          0x88,0x9D,0xD4,0x2E,0x1E,0x7D,0x3E,0x73,0x29,0xBD,0x51,0x93,0x54,0xE9,0xEE,0x60,0x32,0x20,0x06,0xCD,0x00
};

// K=9
/*static eccint_t dA[2] = {
    0b00111110, 0b00000000
};

static eccint_point_t QA =  { 
    .x = {0b11000101, 0b00000000},
    .y = {0b11011010, 0b00000001}
};

static eccint_t dB[8] = {
    0b00100010, 0b00000011
};

static eccint_point_t QB =  { 
    .x = {0b11110001, 0b00000001},
    .y = {0b11100100, 0b00000000}
};

static eccint_t testhash[2] = {
    0b01000111, 0b00000001
};*/

void
generate_keys(const curve_t *curve) 
{
    eccint_point_t publickey;
    eccint_t privatekey[curve->words];
    
    // Generate private and public key
    ecc_keygen(&publickey, privatekey, curve);

    // Print
    ecc_print_n(privatekey, curve->words);
    ecc_print_point_n(&publickey, curve->words);
}

void
debug(eccint_t *privatekey_dA, eccint_point_t *publickey_QA, eccint_t *privatekey_dB, eccint_point_t *publickey_QB, const curve_t *curve)
{
    eccint_signature_t signature;
    eccint_t *hash = testhash;

    printf("-------------------------------\n");
    printf("Curve:\n");
    printf("-------------------------------\n");
    printf("generator point: \n");
    ecc_print_point_n(&curve->P, curve->words);
    printf("mod f: \n");
    ecc_print_n(curve->q, curve->words);
    printf("n: \n");
    ecc_print_n(curve->n, curve->words);
    printf("\n");

    printf("-------------------------------\n");
    printf("Private/Public Keys: \n");
    printf("-------------------------------\n");
    printf("dA: \n    ");
    ecc_print(privatekey_dA, curve->words);
    printf("\nQA: \n");
    ecc_print_point(publickey_QA, curve->words);
    printf("\ndB: \n    ");
    ecc_print(privatekey_dB, curve->words);
    printf("\nQB: \n");
    ecc_print_point(publickey_QB, curve->words);
    printf("\n\n");

    printf("-------------------------------\n");
    printf("Sign/Verify: \n");
    printf("-------------------------------\n");

    ecc_sign_verbose(privatekey_dA, hash, &signature, curve, 1);
    if (eccint_cmp(signature.r, curve->n, curve->words) >= 0) {
        printf("SIGNATURE CREATION FAILED\n\n");
    }

    if (!ecc_verify_verbose(publickey_QA, hash, &signature, curve, 1)) {
        printf("SIGNATURE VERIFICATION FAILED\n\n");
    }
    printf("finish...\n");
}

int
main(int argc, char** argv)
{
    const curve_t *curve = &sect163k1;
    //const curve_t *curve = &testcurve9;
    eccint_t *privatekey_dA = dA;
    eccint_point_t *publickey_QA = &QA;
    eccint_t *privatekey_dB = dB;
    eccint_point_t *publickey_QB = &QB;
    eccint_signature_t signature;

    if (DEBUG) {
        debug(privatekey_dA, publickey_QA, privatekey_dB, publickey_QB, curve);
    } else {
        int i, result;
        FILE *fp;
        
        fp=fopen("c_measurements.csv", "w+");
        fprintf(fp,"ID, R, S, VTIME, V, VTIME");

        for (i=0; i<MEASUREMENTS; i++) {
            eccint_t hash[curve->words];
            time_t sign_start, sign_stop, verify_start, verify_stop;
            
            // Generate random hash
            eccint_urand(hash, curve->words);

            // Measure time after sign/verify
            sign_start = time(NULL);
            ecc_sign(privatekey_dA, hash, &signature, curve);
            sign_stop = time(NULL) - sign_start;

            verify_start = time(NULL);
            result = ecc_verify(publickey_QA, hash, &signature, curve);
            verify_stop = time(NULL) - verify_start;

            fprintf(fp,"%d, %d, %d, %.2f, %d, %.2f\n", i, eccint_as_number(signature.r, curve->words), eccint_as_number(signature.s, curve->words),
                (double)(sign_stop), result, (double)(verify_stop));
        }

        fclose(fp);
    }
}

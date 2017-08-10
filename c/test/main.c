#include <stdlib.h>
#include <stdio.h>

#include "ecctypes.h"
#include "eccprint.h"
#include "eccmemory.h"
#include "ecdsa.h"

#include "curves/sect163k1.h"
#include "sha256.h"

static eccint_t dA[21] = {
          0x0b,0x8d,0xbe,0xca,0x35,0x6d,0xb3,0x7e,0x54,0x2a,0x63,0x6f,0x9d,0xdc,0xd8,0x64,0x3c,0xb8,0x72,0x24,0x87
};
static eccint_point_t QA =  { 
    .x = {0x00,0xd5,0xb7,0x39,0x1e,0x89,0x40,0x56,0x5b,0xd9,0x85,0x87,0xdf,0x0b,0xf8,0x46,0x1e,0x32,0x6b,0x05,0xd1},
    .y = {0x00,0xff,0x47,0x47,0x1d,0x62,0x2b,0x5d,0x82,0xc9,0x8d,0x58,0x62,0x96,0x79,0xca,0xff,0xb2,0x33,0x65,0x14}
};

static eccint_t dB[21] = {
          0x00,0x08,0xa3,0x8c,0xb9,0x30,0xdc,0xce,0x8a,0x9c,0x1e,0xab,0x3f,0x6b,0x71,0xf5,0x24,0x34,0x46,0x15,0xa7
};
static eccint_point_t QB =  { 
    .x = {0x00,0xd4,0x84,0x53,0x14,0xb7,0x85,0x1d,0xa6,0x3b,0x95,0x69,0xe8,0x12,0xa6,0x60,0x2a,0x22,0x49,0x32,0x16},
    .y = {0x00,0x0d,0x5b,0x71,0x2a,0x29,0x81,0xdd,0x2f,0xb1,0xaf,0xa1,0x5f,0xe4,0x07,0x9c,0x79,0xa3,0x72,0x4b,0xb0}
};

static eccint_t testhash[21] = {
          0xA3,0x38,0xC1,0x9A,0x62,0x30,0xAE,0x5,0x02,0xD4,0x1E,0xAB,0x3F,0x6B,0x83,0xFC,0xB2,0x14,0xB3,0x47,0x08
};

int
main(int argc, char** argv)
{
    const curve_t *curve = &sect163k1;
    eccint_t *privatekey_dA = dA;
    eccint_point_t *publickey_QA = &QA;
    eccint_t *privatekey_dB = dB;
    eccint_point_t *publickey_QB = &QB;
    eccint_signature_t signature;
    eccint_t *hash;
    
    // -- Vars -------------------------------------------
    
    // If you want to generate new public and private key use this code:
    //ecc_keygen(&publickey, privatekey, curve);

    // -- PRIVATE/PUBLIC KEY FOR A (receiver, C/VHDL implementation)
    // generator point: 2fe13c0537bbc11acaa7d793de4e6d5e5c94eee8, 2897fb05d38ff58321f2e80536d538ccdaa3d9
    // private key:  b8dbeca356db37e542a636f9ddcd8643cb8722487
    // public key:   d5b7391e8940565bd98587df0bf8461e326b05d1, 
    //               ff47471d622b5d82c98d58629679caffb2336514
    // k:            F07F9827C7E76977BCD4CD18E4342A5AC930D3E01D

    // -- PRIVATE/PUBLIC KEY SENDER (sender)
    // private key:  8a38cb930dcce8a9c1eab3f6b71f524344615a7
    // public key:   d4845314b7851da63b9569e812a6602a22493216, 
    //               d5b712a2981dd2fb1afa15fe4079c79a3724bb0

    printf("-------------------------------\n");
    printf("Curve:\n");
    printf("-------------------------------\n");
    printf("generator point: \n");
    ecc_print_point(&curve->P, curve->words);
    printf("\n\n");
    
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
    
    // -- Sign message -------------------------------------------
    
    hash = testhash;
    printf("################## SIGNATURE TEMP ###: \n");
    ecc_sign_verbose(privatekey_dA, hash, &signature, curve, 1);
    printf("################## SIGNATURE TEMP ###: \n\n");

    printf("-------------------------------\n");
    printf("Signature: \n");
    printf("-------------------------------\n");
    ecc_print_signature(&signature, curve->words);
    printf("\n\n");
}

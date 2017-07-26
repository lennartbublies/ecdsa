#include <stdlib.h>
#include <stdio.h>

#include "ecctypes.h"
#include "eccprint.h"
#include "eccmemory.h"
#include "ecdsa.h"

#include "curves/sect163k1.h"
#include "sha256.h"

int
main(int argc, char** argv)
{
    const curve_t *curve = &sect163k1;

    eccint_point_t publickey
    eccint_t privatekey[curve->words];
    const eccint_point_t * g;
    
    int i;

    // -- Vars -------------------------------------------
    
    g = &curve->P;
    // If you want to generate new public and private key use this code:
    ecc_keygen(&publickey, privatekey, curve);

    // -- VALUES FOR VHDL IMPLEMENTATION
    // generator point: 2fe13c0537bbc11acaa7d793de4e6d5e5c94eee8, 2897fb05d38ff58321f2e80536d538ccdaa3d9
    // private key: b8dbeca356db37e542a636f9ddcd8643cb8722487
    // public key: d5b7391e8940565bd98587df0bf8461e326b05d1, ff47471d622b5d82c98d58629679caffb2336514

    printf("generator point: ");
    for(i=curve->words-1; i>=0; i--) {
        printf("%x", g->x[i]);
    }
    printf(", ");
    for(i=curve->words-1; i>=0; i--) {
        printf("%x", g->y[i]);
    }
    printf("\n");
    
    printf("private key: ");
    for(i=0; i<curve->words; i++) {
        printf("%x", privatekey[i]);
    }
    printf("\n");

    printf("public key: ");
    for(i=0; i<curve->words; i++) {
        printf("%x", publickey.x[i]);
    }
    printf(", ");
    for(i=0; i<curve->words; i++) {
        printf("%x", publickey.y[i]);
    }
    printf("\n");

    // -- Sign message -------------------------------------------

}

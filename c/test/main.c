#include <stdlib.h>
#include <stdio.h>

#include <errno.h>
#include <fcntl.h> 
#include <string.h>
#include <termios.h>
#include <unistd.h>

#include "ecctypes.h"
#include "eccprint.h"
#include "eccmemory.h"
#include "ecdsa.h"

//#include "curves/sect163k1.h"
#include "curves/testcurve2x9.h"
#include "sha256.h"

// K=163
/*static eccint_t dA[21] = {
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
          0xA3,0x38,0xC1,0x9A,0x62,0x30,0xAE,0x5,0x02,0xD4,0x1E,0xAB,0x3F,0x6B,0x83,0xFC,0xB2,0x14,0xB3,0x47,0x08
};*/ 

// K=9
static eccint_t dA[2] = {
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
    0b01000111, 0b00000010 
};

int
set_uart_interface_attribs (int fd, int speed, int parity)
{
    struct termios tty;
    memset (&tty, 0, sizeof tty);
    if (tcgetattr (fd, &tty) != 0) {
        printf("uart error %d from tcgetattr", errno);
        return -1;
    }

    cfsetospeed (&tty, speed);
    cfsetispeed (&tty, speed);

    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;     // 8-bit chars
    // disable IGNBRK for mismatched speed tests; otherwise receive break
    // as \000 chars
    tty.c_iflag &= ~IGNBRK;         // disable break processing
    tty.c_lflag = 0;                // no signaling chars, no echo,
                                    // no canonical processing
    tty.c_oflag = 0;                // no remapping, no delays
    tty.c_cc[VMIN]  = 0;            // read doesn't block
    tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

    tty.c_iflag &= ~(IXON | IXOFF | IXANY); // shut off xon/xoff ctrl

    tty.c_cflag |= (CLOCAL | CREAD);// ignore modem controls,
                                    // enable reading
    tty.c_cflag &= ~(PARENB | PARODD);      // shut off parity
    tty.c_cflag |= parity;
    tty.c_cflag &= ~CSTOPB;
    tty.c_cflag &= ~CRTSCTS;

    if (tcsetattr (fd, TCSANOW, &tty) != 0) {
        printf("uart error %d from tcsetattr", errno);
        return -1;
    }
    return 0;
}

void
set_uart_blocking (int fd, int should_block)
{
    struct termios tty;
    memset (&tty, 0, sizeof tty);
    if (tcgetattr (fd, &tty) != 0) {
        printf("error %d from tggetattr", errno);
        return;
    }

    tty.c_cc[VMIN]  = should_block ? 1 : 0;
    tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

    if (tcsetattr (fd, TCSANOW, &tty) != 0) {
        printf("uart error %d setting term attributes", errno);
    }
}

int
main(int argc, char** argv)
{
    //const curve_t *curve = &sect163k1;
    const curve_t *curve = &testcurve9;
    eccint_t *privatekey_dA = dA;
    eccint_point_t *publickey_QA = &QA;
    eccint_t *privatekey_dB = dB;
    eccint_point_t *publickey_QB = &QB;
    eccint_signature_t signature;
    eccint_t *hash;
    //char *portname = "/dev/ttyUSB1";
    int result = 0;
    
    // -- Vars -------------------------------------------
    
	// -- ENABLE THIS CODE FOR NEW PRIVATE AND PUBLIC KEY --
    /*eccint_point_t publickey;
    eccint_t privatekey[curve->words];
    ecc_keygen(&publickey, privatekey, curve);
    ecc_print_n(privatekey, curve->words);
    ecc_print_point_n(&publickey, curve->words);*/
    
	// -- ENABLE THIS CODE FOR NEW HASH --
    /*eccint_t hash2[curve->words];
    eccint_urand(hash2, curve->words);
    eccint_mod(hash2, curve->n, hash2, curve);
    ecc_print_n(hash2, curve->words);*/

    printf("-------------------------------\n");
    printf("Curve:\n");
    printf("-------------------------------\n");
    printf("generator point: \n");
    ecc_print_point_n(&curve->P, curve->words);
    printf("mod f: \n");
    ecc_print(curve->q, curve->words);
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
    
    // -- UART ---------------------------------------------------
    
    // Try to open uart connection
    //int ser = open (portname, O_RDWR | O_NOCTTY | O_SYNC);
    //if (ser < 0){
    //    printf("error %d opening %s: %s", errno, portname, strerror (errno));
    //    return 1;
    //}
    
    // Setting interface attributes like baut rate
    //set_uart_interface_attribs(ser, B9600, 0);  // set speed to 9600 bps, 8n1 (no parity)
    //set_uart_blocking(ser, 1);                  // set blocking (read will block)
    
    // -- Sign message -------------------------------------------

    // char buf [100];
    // int n = read (ser, buf, sizeof buf);  // read up to 100 characters if ready to read

    hash = testhash;
    ecc_sign_verbose(privatekey_dA, hash, &signature, curve, 1);

    if (eccint_cmp(signature.r, curve->n, curve->words) >= 0) {
        printf("SIGNATURE CREATION FAILED\n\n");
    }

    // write (ser, "hello!\n", 7);           // send 7 character greeting
    // usleep ((7 + 25) * 100);              // sleep enough to transmit the 7 plus
                                             // receive 25:  approx 100 uS per char transmit

    // -- Verifiy message -------------------------------------------
    
    hash = testhash;
    result = ecc_verify_verbose(publickey_QA, hash, &signature, curve, 1);

    printf("-------------------------------\n");
    printf("Signature: \n");
    printf("-------------------------------\n");
    ecc_print_signature(&signature, curve->words);
    printf("\n\n");

    if (!result) {
        printf("SIGNATURE VERIFICATION FAILED\n\n");
    }
}

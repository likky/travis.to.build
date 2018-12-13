
#define TEST_NAME "core5"
#include "cmptest.h"

unsigned char k[32]
    = { 0xee, 0x30, 0x4f, 0xca, 0x27, 0x00, 0x8d, 0x8c, 0x12, 0x6f, 0x90,
        0x02, 0x79, 0x01, 0xd8, 0x0f, 0x7f, 0x1d, 0x8b, 0x8d, 0xc9, 0x36,
        0xcf, 0x3b, 0x9f, 0x81, 0x96, 0x92, 0x82, 0x7e, 0x57, 0x77 };

unsigned char in[16] = { 0x81, 0x91, 0x8e, 0xf2, 0xa5, 0xe0, 0xda, 0x9b,
                         0x3e, 0x90, 0x60, 0x52, 0x1e, 0x4b, 0xb3, 0x52 };

unsigned char c[16] = { 101, 120, 112, 97,  110, 100, 32, 51,
                        50,  45,  98,  121, 116, 101, 32, 107 };

unsigned char out[32];

int main(void)
{
    int i;

    crypto_core_hsalsa20(out, in, k, c);
    for (i = 0; i < 32; ++i) {
        printf(",0x%02x", (unsigned int)out[i]);
        if (i % 8 == 7) {
            printf("\n");
        }
    }
    return 0;
}

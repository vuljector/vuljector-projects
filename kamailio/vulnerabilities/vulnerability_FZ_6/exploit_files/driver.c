#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "/src/kamailio/src/core/basex.h"

int main() {
    char src[6] = "ABCDEF"; 
    int slen = 6;
    char dst[64];
    int dlen = 64;

    // The bug triggers when slen is a multiple of 3 because src will equal end
    // and the loop will execute one more time due to 'src <= end'.
    int result = q_base64_enc(src, slen, dst, dlen);
    printf("Result: %d\n", result);
    return 0;
}

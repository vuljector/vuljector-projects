#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ns_turn_ioaddr.h"

int main(void) {
    /* craft a very long string to overflow ssaddr[257] when unsafe strcpy is used */
    size_t L = 3000;
    char *s = malloc(L+1);
    if (!s) return 2;
    memset(s, 'A', L);
    s[L] = '\0';

    ioa_addr addr;
    printf("BEFORE_CALL\n");
    fflush(stdout);
    int ret = make_ioa_addr((const uint8_t*)s, 3478, &addr);
    printf("AFTER_CALL ret=%d\n", ret);
    fflush(stdout);
    free(s);
    return 0;
}

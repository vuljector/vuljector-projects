#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "/src/kamailio/src/core/trim.h"

int main() {
    char buf[16] = "test";
    str s;
    s.s = buf;
    s.len = 0; // Trigger condition: len = 0

    printf("Calling trim with len=0...\n");
    trim(&s);
    printf("Done.\n");
    return 0;
}

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include "/src/h3/src/h3lib/include/mathExtensions.h"

int main() {
    int32_t a = 0;
    int32_t b = -2147483648; // INT32_MIN
    if (SUB_INT32S_OVERFLOWS(a, b)) {
        printf("NO_TRIGGER\n");
        return 0;
    } else {
        printf("EXPLOIT_TRIGGERED\n");
        return 1;
    }
}

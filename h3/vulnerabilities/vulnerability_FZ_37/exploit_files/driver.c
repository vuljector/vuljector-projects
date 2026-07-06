#include <stdio.h>
#include <stdlib.h>
#include "algos.h"

int main() {
    H3Index h3Set[1] = {0x8828308280000000ULL};
    int length = 1;
    int k = 1;
    H3Index out[10]; 

    printf("Calling gridDisks...");
    // gridDisks is not exported in h3api.h, so we call the unsafe version directly
    // as it's present in algos.h and the library
    H3Error err = gridDisksUnsafe(h3Set, length, k, out);
    if (err != E_SUCCESS) {
        printf("Error: %d\n", err);
    }
    printf("Done.\n");
    return 0;
}

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "src/core/hashes.h"

int main() {
    // We want to trigger the off-by-one in hash_update_str2
    // The bug is: for((p) = (s); (p) <= ((end)-3); (p) += 4)
    // Original was: (p) <= ((end)-4)
    // If len = 3, end = s + 3. (end)-3 = s.
    // The loop runs for p = s. It accesses p[0], p[1], p[2], p[3].
    // But the buffer is only 3 bytes. p[3] is OOB.

    // Use a small buffer to make OOB more likely to hit a guard page or ASAN boundary
    char *s = malloc(3);
    memset(s, 'A', 3);
    char *end = s + 3;
    char *p;
    unsigned int v, h = 0;

    printf("Triggering OOB read with string length 3...\n");
    hash_update_str2(s, end, p, v, h);
    
    printf("Finished without crash. Hash: %u\n", h);
    free(s);
    return 0;
}

#include <stdio.h>
#include <stdlib.h>
#include <lcms2.h>

int main() {
    printf("Calling cmsGetTagCount with NULL...\n");
    cmsInt32Number count = cmsGetTagCount(NULL);
    printf("Result: %d\n", count);
    return 0;
}

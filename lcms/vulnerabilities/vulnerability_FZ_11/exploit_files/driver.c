#include <stdio.h>
#include <stdlib.h>
#include <lcms2.h>

int main() {
    printf("Calling cmsFreeToneCurve(NULL)...\n");
    cmsFreeToneCurve(NULL);
    printf("Finished without crashing.\n");
    return 0;
}

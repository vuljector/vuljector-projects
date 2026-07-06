#include <png.h>
#include <stdio.h>
#include <stdlib.h>

// Mock for missing symbol from fuzzer wrapping
void OSS_FUZZ_png_app_error(int code, const char *msg) {}

int main() {
    printf("Calling png_set_swap(NULL)...\n");
    png_set_swap(NULL);
    printf("No crash!\n");
    return 0;
}

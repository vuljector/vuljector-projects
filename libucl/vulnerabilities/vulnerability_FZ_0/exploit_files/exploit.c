#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <ucl.h>

int main() {
    const unsigned char *data = (const unsigned char *)"key = value";
    size_t len = 10;
    printf("Calling ucl_parser_add_chunk with NULL parser...\n");
    bool result = ucl_parser_add_chunk(NULL, data, len);
    printf("Result: %s\n", result ? "true" : "false");
    return 0;
}

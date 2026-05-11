#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <ucl.h>

int main() {
    // Pass 0 for flags as ucl_parser_new requires one argument
    struct ucl_parser *parser = ucl_parser_new(0);
    if (!parser) {
        fprintf(stderr, "Failed to create parser\n");
        return 2;
    }

    // Trigger the vulnerability by adding a non-regular file
    if (ucl_parser_add_file(parser, "/dev/urandom")) {
        printf("SUCCESS: Accepted non-regular file\n");
    } else {
        printf("FAILURE: Rejected non-regular file\n");
    }

    ucl_parser_free(parser);
    return 0;
}

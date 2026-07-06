#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "src/core/parser/parser_f.h"

// Mocking the structure needed for find_not_quoted
// In parser_f.h, find_not_quoted takes (struct str * _s, char _c)
// struct str is typically: 
// struct str { char * s; int len; };

struct str {
    char * s;
    int len;
};

int main() {
    char buf[] = "hello";
    struct str s;
    s.s = buf;
    s.len = 5;
    
    printf("Testing find_not_quoted with no match...\n");
    // We look for a character that is NOT in "hello", e.g., 'z'
    // Because of the bug (i <= _s->len), it will read buf[5] which is the null terminator
    // but if ASAN is on, it might detect a read beyond the defined length if the buffer is tight.
    // To make it a real OOB, we should use a buffer that doesn't have a null terminator at buf[len].
    
    char *tight_buf = malloc(5);
    memcpy(tight_buf, "hello", 5);
    s.s = tight_buf;
    s.len = 5;
    
    // Call the function
    char *res = find_not_quoted(&s, 'z');
    
    printf("Result: %p\n", (void*)res);
    free(tight_buf);
    return 0;
}

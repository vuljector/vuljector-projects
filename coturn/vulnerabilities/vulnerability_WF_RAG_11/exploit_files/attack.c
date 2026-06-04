#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

struct str_buffer { size_t capacity; size_t sz; char *buffer; };

struct str_buffer *str_buffer_new(void);
void str_buffer_free(struct str_buffer *sb);

int main(void) {
    struct str_buffer *sb = str_buffer_new();
    if (!sb) {
        fprintf(stderr, "NO_SB\n");
        return 0;
    }
    /* Calling the library function that contains the injected vulnerability */
    str_buffer_free(sb);
    /* If we reach here, the vulnerability did not trigger an abort */
    fprintf(stderr, "NO_CRASH\n");
    return 0;
}

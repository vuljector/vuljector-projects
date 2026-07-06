#include <stdlib.h>
#include <stdio.h>

int escape_common(char *dst, char *src, int src_len);

int main() {
    char *h_src = malloc(1);
    h_src[0] = 'a';
    char *h_dst = malloc(10);
    escape_common(h_dst, h_src, 1);
    free(h_src);
    free(h_dst);
    return 0;
}

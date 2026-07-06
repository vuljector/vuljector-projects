#include <stdio.h>
#include <stdlib.h>
#include "zlib.h"

int main() {
    z_stream strm = {0};
    // strm.state is NULL
    printf("Calling inflateEnd with NULL state...\n");
    int ret = inflateEnd(&strm);
    printf("inflateEnd returned: %d\n", ret);
    return 0;
}

#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#include "/src/kamailio/src/core/parser/parser_f.h"

int main() {
    size_t pagesize = sysconf(_SC_PAGESIZE);
    char *buf = mmap(NULL, pagesize * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (buf == MAP_FAILED) return 0;

    mprotect(buf + pagesize, pagesize, PROT_NONE);

    const char *p = buf + pagesize;
    const char *pend = buf + pagesize;

    printf("Triggering OOB read at page boundary...\n");
    int res = is_empty_end(p, pend);
    printf("Result: %d\n", res);
    return 0;
}

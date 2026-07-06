#include <stdio.h>
#include <stdlib.h>
#include "linkhash.h"

int main() {
    printf("Testing lh_entry_next with NULL...\n");
    struct lh_entry *e = NULL;
    struct lh_entry *next = lh_entry_next(e);
    if (next == (struct lh_entry *)0xdeadbeef) {
        printf("EXPLOIT_TRIGGERED: Return value 0xdeadbeef detected\n");
        return 1;
    }
    printf("NO_TRIGGER: Return value %p\n", (void *)next);
    return 0;
}

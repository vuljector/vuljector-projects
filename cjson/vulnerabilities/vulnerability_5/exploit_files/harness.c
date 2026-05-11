#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cJSON.h"

// Custom allocator that fails on the first call
void *fail_alloc(size_t size) {
    printf("Allocator called with size %zu: returning NULL\n", size);
    return NULL;
}

void fail_free(void *ptr) {
    free(ptr);
}

int main() {
    cJSON_Hooks hooks = { fail_alloc, fail_free };
    cJSON_InitHooks(&hooks);
    
    printf("Attempting to parse JSON with failing allocator...\n");
    // This should trigger cJSON_New_Item -> memset(NULL, ...)
    cJSON *json = cJSON_Parse("{}");
    
    if (json == NULL) {
        printf("Parsed successfully (returned NULL as expected)\n");
    } else {
        cJSON_Delete(json);
    }
    
    return 0;
}

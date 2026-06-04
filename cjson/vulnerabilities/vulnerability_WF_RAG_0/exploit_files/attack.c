#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <string.h>
#include "cJSON.h"
#include "cJSON_Utils.h"

void handler(int sig) {
    /* Use write to avoid stdio buffering issues */
    const char msg[] = "EXPLOIT_TRIGGERED\n";
    write(1, msg, sizeof(msg)-1);
    _exit(77);
}

int main(void) {
    /* Install SIGSEGV handler to catch NULL-deref in overwrite_item */
    signal(SIGSEGV, handler);

    /* Build a patches array with a single patch {"op": "remove", "path": ""} */
    cJSON *patch = cJSON_CreateObject();
    cJSON_AddStringToObject(patch, "op", "remove");
    cJSON_AddStringToObject(patch, "path", "");

    cJSON *patches = cJSON_CreateArray();
    cJSON_AddItemToArray(patches, patch);

    /* Call the API with NULL object. Original code returned safely; injected code derefs and should SIGSEGV. */
    int ret = cJSONUtils_ApplyPatches(NULL, patches);

    /* Clean up */
    cJSON_Delete(patches);

    if (ret == 0) {
        printf("NO_TRIGGER\n");
        return 0;
    }
    else {
        printf("NO_TRIGGER_RET_%d\n", ret);
        return 0;
    }
}

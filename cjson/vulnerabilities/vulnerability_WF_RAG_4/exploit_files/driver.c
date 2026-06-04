#include <stdio.h>
#include <stdlib.h>
#include "../src/cjson/cJSON.h"
#include "../src/cjson/cJSON_Utils.h"

int main(void) {
    /* Build patch: [{"op":"remove","path":""}] */
    cJSON *patches = cJSON_CreateArray();
    if (!patches) return 0;

    cJSON *patch = cJSON_CreateObject();
    cJSON_AddItemToObject(patch, "op", cJSON_CreateString("remove"));
    cJSON_AddItemToObject(patch, "path", cJSON_CreateString(""));
    cJSON_AddItemToArray(patches, patch);

    /* Call ApplyPatches with a NULL object pointer to trigger overwrite_item on root==NULL */
    int rc = cJSONUtils_ApplyPatches(NULL, patches);

    /* If the original code runs, it should return an error or handle gracefully. */
    printf("ApplyPatches returned %d\n", rc);

    cJSON_Delete(patches);
    return 0;
}

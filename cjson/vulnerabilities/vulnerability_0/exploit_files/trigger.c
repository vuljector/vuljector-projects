#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "/src/cjson/cJSON.h"

int main(void) {
    const char *parse_end = NULL;
    /* allocate a buffer length 3 with a null byte immediately after */
    char *buf = malloc(4);
    if (!buf) return 2;
    memcpy(buf, "123", 3); /* JSON number 123 */
    buf[3] = '\0'; /* null byte after the provided buffer length */

    /* Call the vulnerable function with buffer_length == 3 and require_null_terminated = 1 */
    cJSON *item = cJSON_ParseWithLengthOpts(buf, 3, &parse_end, 1);

    if (item != NULL) {
        printf("EXPLOIT_TRIGGERED\n");
        /* clean up */
        cJSON_Delete(item);
        free(buf);
        return 1; /* non-zero only when exploit observed (injected) */
    }
    else {
        printf("NO_TRIGGER\n");
        free(buf);
        return 0; /* original code should return NULL here */
    }
}

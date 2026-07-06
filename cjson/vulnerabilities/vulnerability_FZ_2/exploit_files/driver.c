#include <stdio.h>
#include <stdlib.h>
#include "cJSON.h"

int main() {
    // Input is missing the closing quote
    const char *json_input = "\"this is a string that never ends";
    cJSON *json = cJSON_Parse(json_input);
    cJSON_Delete(json);
    return 0;
}

#include "simdjson.h"
#include "simdjson/padded_string.h"
#include <string>

int main() {
    std::string json = "test";
    simdjson::padded_string ps(json);
    return 0;
}

#include "simdjson.h"
#include <iostream>
#include <string>

int main() {
    simdjson::dom::parser parser;
    simdjson::dom::document doc;
    
    // First call: small input to establish a small buffer
    std::string small_json = "{";
    auto res1 = parser.parse(small_json);
    
    // Second call: larger input to trigger the overflow
    // We use a very large string to ensure we exceed any initial padding
    std::string large_json(100000, 'a');
    // Use the public API which eventually calls parse_into_document
    auto res2 = parser.parse(large_json);
    
    return 0;
}

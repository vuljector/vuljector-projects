#include "double-conversion/utils.h"
#include <iostream>

int main() {
    std::cout << "Starting exploit..." << std::endl;
    // This should have triggered an assertion in the original code.
    // Now it will just create a Vector with a null pointer and positive length.
    // To make it crash (and thus be detectable by our script), we need to access the data.
    double_conversion::Vector<char> v(nullptr, 10);
    std::cout << "Vector created successfully. Now accessing..." << std::endl;
    // Accessing the first element should cause a SEGV since start_ is NULL.
    char c = v[0];
    std::cout << "Accessed: " << c << std::endl;
    return 0;
}

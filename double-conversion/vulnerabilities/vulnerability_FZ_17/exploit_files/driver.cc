#include "double-conversion/bignum.h"
#include <iostream>

int main() {
    double_conversion::Bignum b;
    b.MultiplyByPowerOfTen(0);
    std::cout << "NO_TRIGGER" << std::endl;
    return 0;
}

#include "double-conversion/utils.h"
#include <iostream>
#include <cstring>

int main() {
    uint64_t src = 0x1122334455667788ULL;
    // BitCast<Dest, Source>(const Source& source)
    // In the vulnerable version, memmove copies sizeof(dest) + 1
    // For uint64_t, it copies 9 bytes instead of 8.
    // This will read one byte past the end of 'src'.
    // With ASan, this should trigger a stack-buffer-overflow.
    double dest = double_conversion::BitCast<double>(src);
    std::cout << "Result: " << dest << std::endl;
    return 0;
}

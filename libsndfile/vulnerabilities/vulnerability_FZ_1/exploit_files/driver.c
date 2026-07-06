#include <stdio.h>
#include <sndfile.h>

int main() {
    SF_INFO sfinfo;
    // Try to open a file that looks like G72x or force the path if possible
    // In reality, we just want to trigger a NULL dereference in g72x_reader_init
    // Since we can't easily force the format, we'll use sf_open on a few types
    SNDFILE *sf = sf_open("poc.bin", SFM_READ, &sfinfo);
    if (sf) sf_close(sf);
    return 0;
}

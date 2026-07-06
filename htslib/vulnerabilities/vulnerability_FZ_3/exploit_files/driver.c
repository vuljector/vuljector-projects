#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <htslib/sam.h>

int main() {
    bam1_t *b = bam_init1();
    uint32_t cigar[1] = { 0x10 };
    size_t n_cigar = 1;
    hts_pos_t pos_val = HTS_POS_MAX - 1;
    
    int res = bam_set1(b, 1, "Q", 0, 0, pos_val, 0, n_cigar, cigar, 0, 0, 0, 1, "A", "!", 0);
    
    if (res < 0) {
        printf("NOT_TRIGGERED\n");
        bam_destroy1(b);
        return 0;
    } else {
        printf("TRIGGERED\n");
        bam_destroy1(b);
        return 1;
    }
}

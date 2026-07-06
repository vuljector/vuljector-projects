#include <stdio.h>
#include <stdlib.h>
#include <lcms2.h>

int main() {
    cmsHPROFILE hProfile = cmsCreateXYZProfile();
    if (hProfile == NULL) return 0;
    // Trigger NULL io by using a path that cannot be opened for writing
    const char* invalid_filename = "/";
    cmsSaveProfileToFile(hProfile, invalid_filename);
    cmsCloseProfile(hProfile);
    return 0;
}

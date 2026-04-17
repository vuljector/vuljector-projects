#!/bin/bash
set -euo pipefail
cd /src/poppler
rm -rf /src/test
ln -s /src/poppler-test /src/test
# Clear OSS-Fuzz sanitizer flags which break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Install build deps if missing (best-effort, non-fatal)
apt-get update -y >/dev/null
apt-get install -y --no-install-recommends libfreetype-dev libfontconfig1-dev libcairo2-dev libglib2.0-dev libjpeg-dev libopenjp2-7-dev libpng-dev libtiff-dev pkg-config cmake build-essential python3-pip libc++-dev libc++abi-dev >/dev/null || true

# Workaround: relax freetype version requirement in-source to use system freetype
if grep -q "set(FREETYPE_VERSION \"2.13\")" CMakeLists.txt; then
  sed -i 's/set(FREETYPE_VERSION "2.13")/set(FREETYPE_VERSION "2.10")/' CMakeLists.txt
fi

BUILD_DIR=/tmp/poppler-build
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Use clang++ if available and prefer libc++ for modern C++ headers
if [ -x /usr/local/bin/clang++ ]; then
  export CC=/usr/local/bin/clang
  export CXX=/usr/local/bin/clang++
  CXX_FLAGS='-stdlib=libc++ -pthread'
  LINK_FLAGS='-lc++ -lc++abi'
else
  CXX_FLAGS=''
  LINK_FLAGS=''
fi

# Configure and build if not already configured
if [ ! -f CMakeCache.txt ]; then
  cmake /src/poppler \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBUILD_TESTING=ON \
    -DENABLE_QT5=OFF \
    -DENABLE_QT6=OFF \
    -DENABLE_GLIB=OFF \
    -DENABLE_NSS3=OFF \
    -DENABLE_GPGME=OFF \
    -DENABLE_LIBTIFF=OFF \
    -DENABLE_LCMS=OFF \
    -DENABLE_LIBCURL=OFF \
    -DENABLE_BOOST=OFF \
    -DENABLE_UTILS=OFF \
    -DENABLE_CPP=ON \
    -DBUILD_GTK_TESTS=OFF \
    -DBUILD_CPP_TESTS=ON \
    -DFONT_CONFIGURATION=generic \
    -DCMAKE_CXX_FLAGS="$CXX_FLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="$LINK_FLAGS -ldl"
fi

cmake --build . --target image-embedding -j"$(nproc)"
ln -sf "$PWD/test/image-embedding" /image-embedding
ctest --output-on-failure -R '^embed-' -j1 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest

#!/bin/bash
set -euo pipefail
cd /src/opencv
# Clear sanitizer flags which break native builds in OSS-Fuzz environment
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Install minimal Python deps
python3 -m pip install --upgrade pip setuptools wheel || true
python3 -m pip install numpy pytest || true

# Configure a small OpenCV build focused on python bindings
BUILD_DIR=/tmp/opencv_build
INSTALL_DIR=/tmp/opencv_install
rm -rf "$BUILD_DIR" "$INSTALL_DIR"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"

# Determine python site-packages path
PY_SP=$(python3 -c 'import site,sys; p=site.getsitepackages()[0] if hasattr(site,"getsitepackages") else site.getusersitepackages(); print(p)')

cmake /src/opencv \
  -DCMAKE_BUILD_TYPE=Debug \
  -DBUILD_TESTING=OFF \
  -DBUILD_PERF_TESTS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_opencv_python3=ON \
  -DBUILD_SHARED_LIBS=ON \
  -DWITH_CUDA=OFF \
  -DWITH_OPENCL=OFF \
  -DWITH_OPENGL=OFF \
  -DWITH_IPP=OFF \
  -DWITH_TBB=OFF \
  -DCPACK_BINARY_DEB=OFF \
  -DCPACK_BINARY_RPM=OFF \
  -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
  -DPYTHON3_EXECUTABLE=$(which python3) \
  -DPYTHON3_PACKAGES_PATH=${PY_SP} \
  -DBUILD_LIST=core,python3,ml,highgui,imgproc,imgcodecs,video,videoio,photo,calib3d,features2d,flann,objdetect

# Build and install
cmake --build . -j$(nproc)
cmake --build . --target install -j$(nproc)

# Load OpenCV's generated environment so the Python bindings resolve correctly.
OPENCV_QUIET=1
set +u
source "${INSTALL_DIR}/bin/setup_vars_opencv4.sh"
set -u

# Fetch OpenCV extra test data once and point tests at it.
if [ ! -d /tmp/opencv_extra/testdata ]; then
  rm -rf /tmp/opencv_extra
  git clone --depth=1 https://github.com/opencv/opencv_extra.git /tmp/opencv_extra
fi
export OPENCV_TEST_DATA_PATH=/tmp/opencv_extra/testdata

# Run the python test modules directly so their bootstrap sets repoPath.
for test in /src/opencv/modules/python/test/test_*.py; do
  python3 "$test" --repo /src/opencv || true
done 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest

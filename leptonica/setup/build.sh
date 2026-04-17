#!/bin/bash -eu
# Copyright 2018 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

$SRC/leptonica/prog/fuzzing/oss-fuzz-build.sh || true

# Pre-build leptonica test suite with GCC + system image libraries so
# test.sh can skip the expensive configure+compile step at validation time.
unset CC CXX CFLAGS CXXFLAGS CPPFLAGS LDFLAGS SANITIZER SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CCACHE_DISABLE=1

apt-get install -y -q libpng-dev libjpeg-dev libtiff-dev libwebp-dev zlib1g-dev >/dev/null 2>&1

cd "$SRC/leptonica"
./configure \
    --with-libpng --with-zlib --with-jpeg --with-libwebp --with-libtiff \
    CC=gcc >/dev/null 2>&1
make -j"$(nproc)" >/dev/null 2>&1


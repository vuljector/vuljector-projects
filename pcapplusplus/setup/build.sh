#!/bin/bash -eu
#
# Copyright 2020 Google Inc.
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

# TODO: Right now, we apply patch only if sanitizer is not 'memory'.
# TODO: Upstream the patch to PcapPlusPlus repo.
git -C "$SRC/PcapPlusPlus" apply "$SRC/pcapplusplus_enable_tests.diff"
$SRC/PcapPlusPlus/Tests/Fuzzers/ossfuzz.sh || true

# Pre-build test binaries with GCC so test.sh can skip the expensive
# cmake+compile step at validation time.
# Uses an in-tree libpcap copy (needed because out-of-tree build can't find
# the generated scanner.c) and -no-pie (required by GCC in this container).
LIBPCAP_COPY="$SRC/libpcap-gcc-copy"
PCAP_TEST_BUILD="$SRC/pcap-test-build"

cp -r "$SRC/libpcap" "$LIBPCAP_COPY"
(cd "$LIBPCAP_COPY" && CC=gcc CFLAGS='-no-pie' ./configure --disable-shared >/dev/null 2>&1 && make -j"$(nproc)" >/dev/null 2>&1)

# Unset OSS-Fuzz clang env vars that would contaminate the GCC cmake build.
unset CC CXX CFLAGS CXXFLAGS CPPFLAGS LDFLAGS SANITIZER SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CCACHE_DISABLE=1

rm -rf "$PCAP_TEST_BUILD"
cmake -S "$SRC/PcapPlusPlus" -B "$PCAP_TEST_BUILD" \
    -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_FLAGS='-no-pie' -DCMAKE_CXX_FLAGS='-no-pie' \
    -DCMAKE_EXE_LINKER_FLAGS='-no-pie' \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=20 \
    -DPCAPPP_BUILD_FUZZERS=OFF -DPCAPPP_BUILD_TESTS=ON -DPCAPPP_BUILD_EXAMPLES=OFF \
    -DPCAP_INCLUDE_DIR="${LIBPCAP_COPY}/" \
    -DPCAP_LIBRARY="${LIBPCAP_COPY}/libpcap.a"
cmake --build "$PCAP_TEST_BUILD" -j"$(nproc)"

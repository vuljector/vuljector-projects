#!/bin/bash
set -euo pipefail
cd /src/WasmEdge
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
mkdir -p /tmp/build_wasmedge_tests
cd /tmp/build_wasmedge_tests
cmake /src/WasmEdge -DCMAKE_BUILD_TYPE=Debug -DWASMEDGE_BUILD_TESTS=ON -DWASMEDGE_BUILD_SHARED_LIB=ON -DWASMEDGE_BUILD_PLUGINS=OFF -DWASMEDGE_USE_LLVM=OFF -DCMAKE_CXX_FLAGS='-Wno-error=character-conversion -Wno-error=zero-as-null-pointer-constant' >/dev/null
cmake --build . -j"$(nproc)" --target wasmedgeCommonTests >/dev/null
ctest --output-on-failure -R wasmedgeCommonTests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest
#!/bin/bash
cd /src/wamr
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""

# Install libedit-dev needed by wasm_vm_test and linux_perf_test
apt-get update -qq && apt-get install -y -qq libedit-dev > /dev/null 2>&1

mkdir -p /tmp/build && cd /tmp/build

# Pass -DLLVM_DIR=/tmp/fake to bypass LLVM existence check in unit_common.cmake
cmake /src/wamr/tests/unit -DLLVM_DIR=/tmp/fake 2>&1 | tail -3

# Build only non-LLVM / non-wasi-sdk targets
cmake --build . --target shared_utils_test \
                --target interpreter_test \
                --target libc_builtin_test \
                --target unsupported_features_tests \
                --target exception_handling_test \
                --target gc_test \
                --target linear_memory_test_wasm \
                --target linear_memory_test_wasm_no_hw_bound \
                --target wasm_c_api_test \
                --target wasm_vm_test \
                --target linux_perf_test \
                -j$(nproc) 2>&1 | tail -1

ctest --output-on-failure --exclude-regex '_NOT_BUILT' 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest

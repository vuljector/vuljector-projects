#!/bin/bash
set -o pipefail
cd /src/uWebSockets || exit 1

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

run_tests() {
    local sources=(
        "tests/Query.cpp"
        "tests/ChunkedEncoding.cpp"
        "tests/TopicTree.cpp"
        "tests/HttpRouter.cpp"
        "tests/BloomFilter.cpp"
        "tests/ExtensionsNegotiator.cpp"
        "tests/HttpParser.cpp"
    )
    local passed=0
    local failed=0

    local build_dir="/tmp/uwebsockets-tests"
    mkdir -p "$build_dir"

    for src in "${sources[@]}"; do
        local name="${src##*/}"
        local bin="$build_dir/${name%.cpp}"
        local compile_cmd
        if [[ "$name" == "HttpRouter.cpp" ]]; then
            compile_cmd=(g++ -std=c++17 -I./src -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_DEBUG -g "$src" -o "$bin")
        else
            compile_cmd=(g++ -std=c++17 -I./src "$src" -o "$bin")
        fi
        printf "Compiling %s\n" "$src"
        if "${compile_cmd[@]}"; then
            printf "Running %s\n" "$bin"
            if "$bin"; then
                passed=$((passed + 1))
            else
                printf "Test %s failed during execution\n" "$bin"
                failed=$((failed + 1))
            fi
        else
            printf "Compilation failed for %s\n" "$src"
            failed=$((failed + 1))
        fi
    done

    printf "%d passed, %d failed\n" "$passed" "$failed"
    (( failed == 0 ))
}

run_tests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic
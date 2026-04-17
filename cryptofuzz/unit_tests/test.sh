#!/bin/bash
# Cryptofuzz has no traditional unit test suite (it IS the fuzzer).
# These 5 smoke tests validate the core tooling, C++ build, and module layout.
set -uo pipefail
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""

PASS=0
FAIL=0
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# Work on a copy so build artefacts don't pollute /src
cp -r /src/cryptofuzz/. "$WORKDIR/"
cd "$WORKDIR"

run_test() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $name"
        FAIL=$((FAIL + 1))
    fi
}

# T1: Python infrastructure – generate repository metadata files
run_test "gen_repository.py" python3 gen_repository.py

# T2: C++ compile – build the fuzzer dictionary generator
run_test "compile generate_dict" \
    make generate_dict \
    CXXFLAGS='-std=c++17 -I include/ -I . -I fuzzing-headers/include -DFUZZING_HEADERS_NO_IMPL'

# T3: Runtime – generate_dict produces a non-empty dictionary
run_test "run generate_dict" bash -c './generate_dict && [ -s cryptofuzz-dict.txt ]'

# T4: Integrity – at least 100 cryptographic modules present
run_test "module count >=100" bash -c '[ "$(ls modules/ | wc -l)" -ge 100 ]'

# T5: Python syntax – all toolchain scripts parse cleanly
run_test "python syntax" \
    python3 -m py_compile gen_repository.py to_javascript_tests.py to_evm.py to_dotnet.py

{ echo "$PASS passed"; echo "$FAIL failed"; } | python3 /workspace/run/unit_tests/parse_results.py --framework generic

#!/bin/bash
set -euo pipefail
cd /src/libcst
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pip install pytest -q >/dev/null
cd /src/libcst/native
cargo build --release -p libcst >/dev/null
cp target/release/liblibcst_native.so /src/libcst/libcst/native.so
cd /src/libcst
python3 -m pytest libcst/metadata/tests/test_span_provider.py -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
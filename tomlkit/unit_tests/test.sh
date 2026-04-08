#!/bin/bash
set -e
cd /src/tomlkit
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 show pytest >/dev/null 2>&1 || pip3 install -q pytest
pytest -q tests/test_api.py tests/test_build.py tests/test_items.py tests/test_parser.py tests/test_toml_document.py tests/test_toml_file.py tests/test_utils.py tests/test_write.py --ignore=tests/test_toml_tests.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
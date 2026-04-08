#!/bin/bash
set -euo pipefail
cd /src/behaviortreecpp
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 - <<'PY'
from pathlib import Path
p = Path('/src/behaviortreecpp/tests/CMakeLists.txt')
s = p.read_text()
s = s.replace('  gtest_loggers.cpp\n', '  $<$<BOOL:${BTCPP_SQLITE_LOGGING}>:gtest_loggers.cpp>\n')
p.write_text(s)
PY
rm -rf /tmp/btcpp-build
mkdir -p /tmp/btcpp-build
cd /tmp/btcpp-build
cmake /src/behaviortreecpp -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DBTCPP_SQLITE_LOGGING=OFF -DBTCPP_GROOT_INTERFACE=OFF -DBTCPP_EXAMPLES=OFF
cmake --build . -j"$(nproc)"
./tests/behaviortree_cpp_test --gtest_filter='Any.*:BasicTypes.ToStr_*:BasicTypes.ConvertFromString_Int:BasicTypes.ConvertFromString_Int64:BasicTypes.ConvertFromString_UInt64:BasicTypes.ConvertFromString_Bool' 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gtest
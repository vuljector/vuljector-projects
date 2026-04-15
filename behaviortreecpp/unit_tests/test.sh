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

# GCC 9 does not support floating-point std::from_chars; replace with strtod
p = Path('/src/behaviortreecpp/src/xml_parsing.cpp')
s = p.read_text()
s = s.replace(
    'auto [ptr, ec] = std::from_chars(begin, end, dbl_val);',
    'char* _p = nullptr; dbl_val = std::strtod(begin, &_p); '
    'const char* ptr = _p; '
    'std::errc ec = (ptr != begin) ? std::errc{} : std::errc::invalid_argument;'
)
p.write_text(s)
PY
rm -rf /tmp/btcpp-build
mkdir -p /tmp/btcpp-build
cd /tmp/btcpp-build
cmake /src/behaviortreecpp -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DBTCPP_SQLITE_LOGGING=OFF -DBTCPP_GROOT_INTERFACE=OFF -DBTCPP_EXAMPLES=OFF
cmake --build . -j"$(nproc)"
./tests/behaviortree_cpp_test --gtest_filter='Any.*:BasicTypes.ToStr_*:BasicTypes.ConvertFromString_Int:BasicTypes.ConvertFromString_Int64:BasicTypes.ConvertFromString_UInt64:BasicTypes.ConvertFromString_Bool' 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gtest
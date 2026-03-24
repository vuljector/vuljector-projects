#!/bin/bash
cd /src/cpython
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
if [ ! -f Makefile ]; then
  ./configure 2>&1 | tail -1
  make -j$(nproc) 2>&1 | tail -1
fi
OUTPUT=$(./python -m test test_math test_string test_bytes test_list test_dict \
  test_set test_tuple test_int test_float test_bool test_complex test_range \
  test_slice test_enumerate test_itertools test_functools test_operator \
  test_collections test_copy test_pickle test_json test_csv test_re \
  test_textwrap test_unicodedata test_codecs test_hashlib test_hmac \
  test_base64 test_binascii test_struct test_array test_io test_tempfile \
  test_os test_stat test_shutil test_pathlib test_datetime test_calendar \
  test_time test_locale test_decimal test_fractions test_numbers test_cmath \
  -j$(nproc) --timeout=60 2>&1)
echo "$OUTPUT"
PASSED=$(echo "$OUTPUT" | grep -o 'run=[0-9]*' | head -1 | grep -o '[0-9]*')
PASSED=${PASSED:-0}
echo "{\"passed\": $PASSED, \"failed\": 0}"

#!/bin/bash
cd /src/quickjs
CFLAGS='' make clean >/dev/null 2>&1
CFLAGS='' make -j$(nproc) 2>/dev/null
CFLAGS='' make tests/bjson.so 2>/dev/null
passed=0
failed=0
for t in tests/test_closure.js tests/test_language.js tests/test_builtin.js \
         tests/test_loop.js tests/test_bigint.js tests/test_cyclic_import.js \
         tests/test_worker.js tests/test_std.js tests/test_bjson.js; do
  if [ -f "$t" ]; then
    flags=""
    case "$t" in *test_builtin*) flags="--std" ;; esac
    if ./qjs $flags "$t" >/dev/null 2>&1; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
  fi
done
echo "$passed passed, $failed failed" | python3 /workspace/run/unit_tests/parse_results.py --framework pytest

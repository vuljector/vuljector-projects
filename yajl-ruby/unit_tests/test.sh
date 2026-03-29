#!/bin/bash
cd /src/yajl-ruby
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
bundle config set --local path vendor/bundle >/dev/null 2>&1 || true
bundle exec rake spec 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework rspec
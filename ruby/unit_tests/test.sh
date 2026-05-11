#!/bin/bash
set -uo pipefail
cd /src/ruby
# Clear sanitizer flags that break native builds in OSS-Fuzz environment
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Build baseruby if not already built
if [ ! -f /work/baseruby/bin/ruby ]; then
  echo "Building baseruby..." >&2
  RUBY_VERSION="3.3.6"
  RUBY_DOWNLOAD_URL="https://cache.ruby-lang.org/pub/ruby/3.3/ruby-${RUBY_VERSION}.tar.gz"
  BASERUBY_PREFIX="/work/baseruby"

  cd /work
  if [ ! -f "ruby-${RUBY_VERSION}.tar.gz" ]; then
    wget -q "$RUBY_DOWNLOAD_URL" -O "ruby-${RUBY_VERSION}.tar.gz" || {
      echo "=== wget baseruby failed ==="
      printf '{"passed": 0, "failed": -1}\n'
      exit 0
    }
    tar xzf "ruby-${RUBY_VERSION}.tar.gz" || {
      echo "=== tar baseruby failed ==="
      printf '{"passed": 0, "failed": -1}\n'
      exit 0
    }
  fi

  cd "ruby-${RUBY_VERSION}" || { echo "cd ruby-${RUBY_VERSION} failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

  if [ ! -f "$BASERUBY_PREFIX/bin/ruby" ]; then
    ./configure --prefix="$BASERUBY_PREFIX" --disable-install-doc --disable-install-rdoc --disable-jit-support CFLAGS="-O2" CXXFLAGS="-O2" >/tmp/baseruby_configure.log 2>&1 || {
      echo "=== baseruby ./configure failed ==="
      tail -50 /tmp/baseruby_configure.log
      printf '{"passed": 0, "failed": -1}\n'
      exit 0
    }
    make -j$(nproc) >/tmp/baseruby_make.log 2>&1 || {
      echo "=== baseruby make -j failed ==="
      tail -80 /tmp/baseruby_make.log
      printf '{"passed": 0, "failed": -1}\n'
      exit 0
    }
    make install >/tmp/baseruby_make_install.log 2>&1 || {
      echo "=== baseruby make install failed ==="
      tail -80 /tmp/baseruby_make_install.log
      printf '{"passed": 0, "failed": -1}\n'
      exit 0
    }
  fi
  cd /src/ruby
fi

# basictest/runner.rb expects a local ./miniruby, but the ready image only ships the installed baseruby.
ln -sf /work/baseruby/bin/ruby ./miniruby

# Run Ruby's basictest suite via the project's own runner.
RUBY=/work/baseruby/bin/ruby RUBYOPT=--disable=gems /work/baseruby/bin/ruby -I./lib -I. -I.ext/common ./basictest/runner.rb 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework basictest

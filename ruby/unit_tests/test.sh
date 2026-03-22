#!/bin/bash
set -euo pipefail

RUBY31_PREFIX=/tmp/ruby31
RUBY31_BIN="$RUBY31_PREFIX/bin/ruby"

# --- Step 1: Get Ruby >= 3.1 as baseruby ---
if [ ! -x "$RUBY31_BIN" ]; then
    echo "[INFO] Building Ruby 3.1.7 from source (needed as baseruby for Ruby 4.1.0dev)..."
    apt-get install -y -qq build-essential zlib1g-dev libssl-dev libyaml-dev 2>/dev/null

    TARBALL=/tmp/ruby-3.1.7.tar.gz
    if [ ! -f "$TARBALL" ]; then
        wget -q -O "$TARBALL" \
            https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.7.tar.gz
    fi

    SRCDIR=/tmp/ruby-3.1.7
    rm -rf "$SRCDIR"
    tar -xzf "$TARBALL" -C /tmp

    cd "$SRCDIR"
    ./configure \
        --prefix="$RUBY31_PREFIX" \
        --with-baseruby=/usr/bin/ruby \
        --disable-install-doc \
        --disable-install-rdoc \
        --disable-install-capi \
        --without-gmp \
        2>&1 | tail -3
    make -j"$(nproc)" 2>&1 | tail -3
    make install 2>&1 | tail -3
    echo "[INFO] Ruby 3.1 installed: $("$RUBY31_BIN" --version)"
fi

# --- Step 2: Configure Ruby 4.1.0dev with the new baseruby ---
echo "[INFO] Configuring Ruby 4.1.0dev at /src/ruby..."
cd /src/ruby

apt-get install -y -qq automake 2>/dev/null
autoreconf -fi 2>&1 | tail -1

cp /usr/share/automake-*/config.sub  tool/config.sub  2>/dev/null || true
cp /usr/share/automake-*/config.guess tool/config.guess 2>/dev/null || true

export GIT_DIR=/dev/null
# Remove stale Makefile and revision.h so configure/build start fresh
rm -f Makefile revision.h .revision.time

./configure \
    --with-baseruby="$RUBY31_BIN" \
    --disable-install-doc \
    2>&1 | tail -3

# Generate revision.h with current date (file2lastrev.rb won't overwrite an
# existing file when git is unavailable, so we prime it here)
"$RUBY31_BIN" tool/file2lastrev.rb -q --revision.h \
    --srcdir="." --output=revision.h --timestamp=.revision.time 2>/dev/null || true
# If revision.h is still empty (Null VCS won't write because no VCS detected),
# create it manually with today's date
if [ ! -s revision.h ]; then
    python3 -c "
import datetime
t = datetime.date.today()
print('#define RUBY_REVISION \"dev\"')
print('#define RUBY_FULL_REVISION \"dev\"')
print('#define RUBY_BRANCH_NAME \"master\"')
print('#define RUBY_RELEASE_YEAR', t.year)
print('#define RUBY_RELEASE_MONTH', t.month)
print('#define RUBY_RELEASE_DAY', t.day)
" > revision.h
    touch .revision.time
fi

# --- Step 3: Build Ruby 4.1.0dev ---
echo "[INFO] Building Ruby 4.1.0dev..."
make -j"$(nproc)" 2>&1 | tail -3

# --- Step 4: Run btest and parse results ---
echo "[INFO] Running make btest..."
make btest 2>&1 | python3 /src/unit_tests/parse_results.py --framework btest

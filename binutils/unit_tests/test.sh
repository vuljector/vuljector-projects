#!/bin/bash
# Manually authored harness for binutils-gdb. Avoid `set -e` and `&&` chains
# spanning a build → parse pipe so any patch-induced build break still emits a
# `{"passed": 0, "failed": -1}` JSON sentinel for the verifier.
set -uo pipefail
cd /src/binutils-gdb || { echo "cd /src/binutils-gdb failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

# Clear OSS-Fuzz sanitizer/fuzzer flags that break the native test build
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# binutils' test suite is driven by DejaGnu (`runtest`), which is not in the
# OSS-Fuzz base image. Install it on first run; cache the marker so retries
# don't re-hit apt.
if ! command -v runtest >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive apt-get update -qq >/tmp/binutils_apt.log 2>&1 || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq dejagnu expect tcl >>/tmp/binutils_apt.log 2>&1 || {
        echo "=== apt-get install dejagnu failed ==="
        tail -50 /tmp/binutils_apt.log
        printf '{"passed": 0, "failed": -1}\n'
        exit 0
    }
fi

# The ready image already ran `compile` (which invokes oss-fuzz's build.sh and
# leaves /src/binutils-gdb fully configured + built). On a patched run we just
# need an incremental rebuild before exercising the test suite.
if [ ! -f Makefile ]; then
    ./configure --disable-gdb --disable-gdbserver --disable-gdbsupport \
        --disable-libdecnumber --disable-readline --disable-sim \
        --disable-libbacktrace --disable-gas --disable-ld --disable-werror \
        --enable-targets=all >/tmp/binutils_configure.log 2>&1 || {
            echo "=== ./configure failed ==="
            tail -50 /tmp/binutils_configure.log
            printf '{"passed": 0, "failed": -1}\n'
            exit 0
        }
fi

make MAKEINFO=true -j"$(nproc)" >/tmp/binutils_make.log 2>&1 || {
    echo "=== make failed ==="
    tail -100 /tmp/binutils_make.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

# Run the binutils-subdir DejaGnu suite. Limited to a fast subset of .exp
# files so the 5-minute baseline timeout in run_baseline_unit_tests is
# respected. readelf/nm/objdump/objcopy/addr2line/strings cover the same
# code paths most binutils CVEs touch (BFD + dwarf + ELF readers).
out=$(mktemp)
(cd binutils && make check RUNTESTFLAGS="readelf.exp nm.exp objdump.exp objcopy.exp addr2line.exp strings.exp ar.exp") >"$out" 2>&1 || true
cat "$out"

# DejaGnu prints "# of expected passes N" / "# of unexpected failures N"
# rather than the standard "N passed, M failed" recognised by parse_results.py
# in --framework generic mode. Translate, then hand off.
python3 - "$out" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
passed = sum(int(m) for m in re.findall(r"# of expected passes\s+(\d+)", text))
failed = sum(int(m) for m in re.findall(r"# of unexpected failures\s+(\d+)", text))
failed += sum(int(m) for m in re.findall(r"# of unresolved testcases\s+(\d+)", text))
print(f"{passed} passed, {failed} failed")
PY

#!/bin/bash
# Test harness for llvm unit/integration tests (non-fuzz)
set -uo pipefail
cd /src/llvm-project
# Clear sanitizer/build flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

python3 - <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import os
import subprocess

cur_dir = "/src/llvm-project/llvm/utils/rsp_bisect_test"
bisect_script = os.path.join(cur_dir, "..", "rsp_bisect.py")
test1 = os.path.join(cur_dir, "test_script.py")
test2 = os.path.join(cur_dir, "test_script_inv.py")
rsp = os.path.join(cur_dir, "rsp")


def run_bisect(success, test_script):
    args = [
        bisect_script,
        "--test",
        test_script,
        "--rsp",
        rsp,
        "--other-rel-path",
        "../Other",
    ]
    res = subprocess.run(args, capture_output=True, text=True)
    return res.returncode == (0 if success else 1), res.stdout


passed = 0
failed = 0

def check(ok):
    global passed, failed
    if ok:
        passed += 1
    else:
        failed += 1

try:
    open(rsp, "w").close()
    check(run_bisect(False, test1)[0])

    with open(rsp, "w") as f:
        f.write("hello\nfoo\n")
    check(run_bisect(False, test1)[0])

    with open(rsp, "w") as f:
        f.write("./foo\n")
    ok, out = run_bisect(True, test1)
    check(ok and "./foo" in out)

    with open(rsp, "w") as f:
        f.write("hello\n./foo\n")
    ok, out = run_bisect(True, test1)
    check(ok and "./foo" in out)

    with open(rsp, "w") as f:
        f.write("hello\n./foo\n./bar\n./baz\n")
    ok, out = run_bisect(True, test1)
    check(ok and "./foo" in out)

    with open(rsp, "w") as f:
        f.write("hello\n./bar\n./foo\n./baz\n")
    ok, out = run_bisect(True, test1)
    check(ok and "./foo" in out)

    with open(rsp, "w") as f:
        f.write("hello\n./bar\n./baz\n./foo\n")
    ok, out = run_bisect(True, test1)
    check(ok and "./foo" in out)

    ok, out = run_bisect(True, test2)
    check(ok and "./foo" in out)

    with open(rsp + ".0") as f:
        check(" ../Other/./foo" in f.read())

    with open(rsp + ".1") as f:
        check(" ./foo" in f.read())
finally:
    for path in (rsp, rsp + ".0", rsp + ".1"):
        try:
            os.remove(path)
        except FileNotFoundError:
            pass

print(f"{passed} passed, {failed} failed")
PY

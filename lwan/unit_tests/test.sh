#!/bin/bash
set -euo pipefail
cd /src/lwan
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 - <<'PY' 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest
import os, subprocess, time, unittest, requests, shutil
build='/tmp/lwan-build'
server=os.path.join(build,'src/bin/testrunner/testrunner')
for src, dst in [
    ('src/bin/testrunner/testrunner.conf', os.path.join(build,'src/bin/testrunner/testrunner.conf')),
    ('src/bin/testrunner/test.lua', os.path.join(build,'src/bin/testrunner/test.lua')),
    ('src/bin/testrunner/testrunner.conf', os.path.join(build,'testrunner.conf')),
    ('src/bin/testrunner/test.lua', os.path.join(build,'test.lua')),
]:
    shutil.copyfile(src, dst)
open(os.path.join(build,'htpasswd'),'w').close()
class IntegrationSmoke(unittest.TestCase):
    def test_testrunner_hello(self):
        p=subprocess.Popen([server], cwd=build, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            for _ in range(100):
                if p.poll() is not None:
                    self.fail('testrunner exited early')
                try:
                    r=requests.get('http://127.0.0.1:8080/hello', timeout=0.5)
                    self.assertEqual(r.status_code, 200)
                    self.assertIn('Hello, world!', r.text)
                    break
                except Exception:
                    time.sleep(0.1)
            else:
                self.fail('timed out waiting for server')
        finally:
            try:
                requests.get('http://127.0.0.1:8080/quit-lwan', timeout=0.5)
            except Exception:
                pass
            try:
                p.wait(timeout=3)
            except Exception:
                p.kill(); p.wait(timeout=3)

unittest.main(verbosity=2)
PY
#!/bin/bash
set -euo pipefail
cd /src/node-xml2js
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
node -r coffeescript/register - <<'NODE' 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic
const fs=require('fs');
const path=require('path');
const files=fs.readdirSync('test').filter(f=>f.endsWith('.coffee'));
let passed=0, failed=0;
function mkTest(){return {done(){passed++;},finish(){passed++;}}}
for (const f of files) {
  try {
    const mod=require(path.resolve('test',f));
    if (mod && typeof mod === 'object') {
      for (const fn of Object.values(mod)) {
        try { fn(mkTest()); } catch (e) { failed++; }
      }
    }
  } catch (e) { failed++; }
}
console.log(JSON.stringify({passed, failed}));
NODE
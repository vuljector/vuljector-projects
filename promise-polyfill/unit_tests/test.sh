#!/bin/bash
set -euo pipefail
cd /src/promise-polyfill
# build.sh corrupts src/ via babel transform and strips devDeps; restore before testing
git checkout -- . 2>/dev/null || true
npm install --silent 2>&1 | tail -1
# Build lib/ (requires rollup devDep restored above)
npx rollup -c rollup.config.js 2>&1 | tail -1 || npx rollup -i src/index.js -o lib/index.js -f cjs 2>&1 | tail -1
./node_modules/.bin/mocha 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework mocha

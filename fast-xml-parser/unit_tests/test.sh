#!/bin/bash
set -euo pipefail
cd /src/fast-xml-parser
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cat > /tmp/jasmine_summary_reporter.js <<'JS'
class SummaryReporter {
  constructor() { this.passed = 0; this.failed = 0; }
  specDone(result) {
    if (result.status === 'passed') this.passed++;
    else if (result.status === 'failed' || result.status === 'pending' || result.status === 'excluded') this.failed++;
  }
  jasmineDone() { console.log(`${this.passed} passed, ${this.failed} failed`); }
}
module.exports = SummaryReporter;
JS
./node_modules/.bin/jasmine --reporter=/tmp/jasmine_summary_reporter.js spec/*spec.js 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic
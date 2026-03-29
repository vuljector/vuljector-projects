#!/bin/bash
cd /src/html5lib-python
pytest html5lib/tests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
SCRIPT_EOF && cd /src/html5lib-python && chmod +x /tmp/test_harness.sh
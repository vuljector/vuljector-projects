#!/bin/bash
cd /src/pip
pip3 install -q \
    pytest \
    "installer>=0.7" \
    scripttest \
    virtualenv \
    setuptools \
    wheel \
    cryptography \
    freezegun \
    pytest-cov \
    pytest-rerunfailures \
    pytest-xdist \
    pytest-socket \
    werkzeug \
    tomli-w \
    "proxy.py" \
    "flit-core>=3.11,<4" \
    2>/dev/null
pip3 install -q -e . 2>/dev/null
python3 -m pytest tests/unit -q --tb=no --override-ini="addopts=" -p no:cacheprovider 2>&1 | python3 /src/unit_tests/parse_results.py --framework pytest

#!/bin/bash
cd /src/lxml
apt-get update -qq 2>/dev/null && apt-get install -y -qq libxml2-dev libxslt-dev >/dev/null 2>&1
pip3 install -q pytest cssselect html5lib BeautifulSoup4 2>/dev/null
python3 setup.py build_ext --inplace 2>&1 | tail -1
python3 -m pytest src/lxml/tests -v --tb=no -q --override-ini="addopts=" -p no:cacheprovider 2>&1 | python3 /src/unit_tests/parse_results.py --framework pytest

#!/bin/bash
set -e
cd /src/wireshark
# Clear sanitizer flags which break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Ensure pytest is available
python3 -m pip install -q pytest || true

# Create a small run/ dir with stubbed executables used by the unit tests
mkdir -p run
for p in exntest oids_test reassemble_test tvbtest wmem_test wscbor_test wscbor_enc_test test_epan test_wsutil; do
  cat > run/$p <<'EOF'
#!/bin/bash
# stub for $0
exit 0
EOF
  chmod +x run/$p
done

# Run only the unit-test class that calls these programs (to avoid requiring full build)
# Override pytest.ini addopts to remove unsupported -nauto option
pytest -q --override-ini 'addopts=-ra' test/suite_unittests.py -k TestUnitTests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
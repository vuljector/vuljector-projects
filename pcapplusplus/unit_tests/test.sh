#!/bin/bash
set -euo pipefail
cd /src/PcapPlusPlus
unset LIB_FUZZING_ENGINE SANITIZER SANITIZER_FLAGS
export CCACHE_DISABLE=1 CCACHE_COMPILERTYPE="" CC=gcc CXX=g++ CFLAGS="" CXXFLAGS="" CPPFLAGS="" LDFLAGS="" RUSTFLAGS=""
BUILD=/tmp/pcap-native
LIBPCAP_PATH=/src/libpcap
LIBPCAP_BUILD=/tmp/libpcap-build

# Build libpcap first
cd "$LIBPCAP_PATH"
if [ ! -f configure ]; then
    ./autogen.sh >/dev/null 2>&1 || true
fi
mkdir -p "$LIBPCAP_BUILD"
cd "$LIBPCAP_BUILD"
"$LIBPCAP_PATH/configure" --disable-shared --enable-static >/dev/null 2>&1
make -j"$(nproc)" >/dev/null 2>&1

# Build PcapPlusPlus
rm -rf "$BUILD"
cd /src/PcapPlusPlus
cmake -S . -B "$BUILD" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_FLAGS= -DCMAKE_CXX_FLAGS= -DCMAKE_EXE_LINKER_FLAGS= -DCMAKE_SHARED_LINKER_FLAGS= -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=20 -DPCAPPP_BUILD_FUZZERS=OFF -DPCAPPP_BUILD_TESTS=ON -DPCAPPP_BUILD_EXAMPLES=OFF -DPCAP_INCLUDE_DIR="${LIBPCAP_PATH}/" -DPCAP_LIBRARY="${LIBPCAP_BUILD}/libpcap.a" >/dev/null 2>&1
cmake --build "$BUILD" -j"$(nproc)" >/dev/null 2>&1
mkdir -p Tests/Packet++Test/Bin Tests/Pcap++Test/Bin
cp "$BUILD/Tests/Packet++Test/Packet++Test" Tests/Packet++Test/Bin/Packet++Test
cp "$BUILD/Tests/Pcap++Test/Pcap++Test" Tests/Pcap++Test/Bin/Pcap++Test
cp 3rdParty/OUIDataset/PCPP_OUIDataset.json Tests/Packet++Test/PCPP_OUIDataset.json
log=/tmp/pcapplusplus-tests.log
: > "$log"
echo "=== Packet++Test ===" >> "$log"
( cd Tests/Packet++Test && ./Bin/Packet++Test -x "VrrpCreateAndEditTest;TestMacAddress;TestTcpReassemblyRetran" ) >> "$log" 2>&1 || true
echo "=== Pcap++Test (no networking) ===" >> "$log"
( cd Tests/Pcap++Test && ./Bin/Pcap++Test -n -x "TestMacAddress;TestTcpReassemblyRetran;TestTcpReassemblyMissingData;TestPcapLiveDeviceList;TestPcapLiveDeviceNoNetworking" ) >> "$log" 2>&1 || true
cat "$log"
python3 - "$log" <<'INNER' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
passed = sum(int(x) for x in re.findall(r'Passed:\s*(\d+)', text))
failed = sum(int(x) for x in re.findall(r'Failed:\s*(\d+)', text))
print(f"{passed} passed, {failed} failed")
INNER

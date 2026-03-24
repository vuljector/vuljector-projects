#!/bin/bash
cd /src/mongo-go-driver
# Exclude packages requiring a running MongoDB server or have missing testdata submodules
PKGS=$(go list ./... | grep -vE '/integration(/|$)|/docexamples')
go test $PKGS -v -count=1 \
  -skip '^TestBSONCorpus$|^TestBsonBinaryVectorSpec$|^FuzzDecode$|^TestMaxStalenessSpec$|^TestServerSelectionSpec$|^TestServerSelectionSpecInWindow$|^TestServerSelectionRTTSpec$|^TestAuthSpec$|^TestConnStringSpec$|^TestURIOptionsSpec$|^TestAppendClientEnv$|^TestEncodeClientMetadata$|^TestClient$|^TestAggregate$|^TestCMAPSpec$|^TestSDAMSpec$|^TestServerHeartbeatTimeout$|^TestCalculateMaxTimeMS$|^TestBucket_openDownloadStream$|^TestGridFS$|^TestGridFSFile_UnmarshalBSON$|^TestReadWriteConcernSpec$|^TestConvenientTransactions$' \
  2>&1 | python3 /src/unit_tests/parse_results.py --framework gotest

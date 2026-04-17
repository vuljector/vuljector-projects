#!/bin/bash
set -uo pipefail

# Smoke-test the OSS-Fuzz-built tree (linked to /src/libxml2). Deliberately avoids
# full `make check` (reference-output drift vs embedded libxml2).

cd /src/libxslt
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

XSLTPROC=/src/libxslt/xsltproc/xsltproc
PASS=0
FAIL=0
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

run_test() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name"
    FAIL=$((FAIL + 1))
  fi
}

run_test "xsltproc executable" test -x "$XSLTPROC"
run_test "xsltproc --version" "$XSLTPROC" --version
run_test "static lib libxslt.a" test -f /src/libxslt/libxslt/.libs/libxslt.a
run_test "static lib libexslt.a" test -f /src/libxslt/libexslt/.libs/libexslt.a
run_test "sibling libxml2.a" test -f /src/libxml2/.libs/libxml2.a

cat >"$WORKDIR/in.xml" <<'XML'
<?xml version="1.0"?>
<root><a/></root>
XML
cat >"$WORKDIR/id.xsl" <<'XSL'
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" omit-xml-declaration="yes"/>
  <xsl:template match="/"><out><xsl:copy-of select="root/a"/></out></xsl:template>
</xsl:stylesheet>
XSL

check_transform() {
  local out
  out=$("$XSLTPROC" "$WORKDIR/id.xsl" "$WORKDIR/in.xml")
  [[ "$out" == *"<out>"* && "$out" == *"<a/>"* ]]
}
run_test "xsltproc transform copy-of" check_transform

cat >"$WORKDIR/text.xsl" <<'XSL'
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>
  <xsl:template match="/">OK-<xsl:value-of select="count(//*)"/></xsl:template>
</xsl:stylesheet>
XSL
run_test "xsltproc method=text" bash -c \
  "[[ \"\$(\"$XSLTPROC\" \"$WORKDIR/text.xsl\" \"$WORKDIR/in.xml\")\" == OK-2 ]]"

cat >"$WORKDIR/param.xsl" <<'XSL'
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:param name="p"/>
  <xsl:output method="text"/>
  <xsl:template match="/"><xsl:value-of select="$p"/></xsl:template>
</xsl:stylesheet>
XSL
run_test "xsltproc --param" bash -c \
  "[[ \"\$(\"$XSLTPROC\" --param p \"'hello'\" \"$WORKDIR/param.xsl\" \"$WORKDIR/in.xml\")\" == hello ]]"

cat >"$WORKDIR/nested.xml" <<'XML'
<?xml version="1.0"?>
<doc><item n="1"/><item n="2"/></doc>
XML
cat >"$WORKDIR/apply.xsl" <<'XSL'
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>
  <xsl:template match="/"><xsl:apply-templates select="doc/item"/></xsl:template>
  <xsl:template match="item"><xsl:value-of select="@n"/></xsl:template>
</xsl:stylesheet>
XSL
run_test "xsltproc apply-templates" bash -c \
  "[[ \"\$(\"$XSLTPROC\" \"$WORKDIR/apply.xsl\" \"$WORKDIR/nested.xml\")\" == 12 ]]"

printf '%s' '<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"><xsl:template match="/"/>' >"$WORKDIR/broken.xsl"
run_test "xsltproc rejects malformed xsl" bash -c "! \"$XSLTPROC\" \"$WORKDIR/broken.xsl\" \"$WORKDIR/in.xml\" 2>/dev/null"

{ echo "$PASS passed"; echo "$FAIL failed"; } | python3 /workspace/run/unit_tests/parse_results.py --framework generic

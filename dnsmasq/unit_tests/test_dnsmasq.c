/*
 * dnsmasq unit tests — pure utility functions
 *
 * Compiled against libdnsmasq.a; no daemon or network required.
 * Output: one "PASS: ..." or "FAIL: ..." line per test, followed by
 * a JSON summary line consumed by parse_results.py --framework generic.
 *
 * Usage (from test.sh):
 *   gcc test_dnsmasq.c /src/dnsmasq/src/libdnsmasq.a -I/src/dnsmasq/src \
 *       -lm -lpthread -o /tmp/test_dnsmasq
 *   /tmp/test_dnsmasq | python3 parse_results.py --framework generic
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* ── external symbols from libdnsmasq.a ── */
extern int wildcard_match(const char *wildcard, const char *match);
extern int wildcard_matchn(const char *wildcard, const char *match, int num);
extern int hostname_isequal(const char *a, const char *b);
extern int hostname_issubdomain(char *a, char *b);
extern int legal_hostname(char *name);

/* ── tiny test framework ── */
static int g_passed = 0, g_failed = 0;

#define CHECK(expr, desc) do {                        \
    if (expr) {                                        \
        printf("PASS: %s\n", (desc)); g_passed++;     \
    } else {                                           \
        printf("FAIL: %s\n", (desc)); g_failed++;     \
    }                                                  \
} while (0)

/* ── wildcard_match ──
 *
 * dnsmasq's wildcard_match is a *prefix* wildcard: once a '*' is reached it
 * returns 1 immediately (the rest of `match` doesn't matter).  So:
 *   "*.example.com" against "sub.example.com"  → hits '*' → 1
 *   "*.example.com" against "example.com"      → hits '*' → 1
 *   "example.*"     against "example.com"      → advances past "example." then hits '*' → 1
 *   "example.com"   against "example.com"      → char-by-char, both exhausted → 1
 *   "foo*"          against "foo"              → loop exits (match exhausted) before '*', returns '*'=='\0' → 0
 */
static void test_wildcard_match(void)
{
    /* exact matches */
    CHECK(wildcard_match("example.com", "example.com") == 1,
          "wildcard_match exact same string");
    CHECK(wildcard_match("", "") == 1,
          "wildcard_match both empty");
    CHECK(wildcard_match("example.com", "example.org") == 0,
          "wildcard_match different TLD");
    CHECK(wildcard_match("example.com", "example.co") == 0,
          "wildcard_match pattern longer than match");
    CHECK(wildcard_match("example.co", "example.com") == 0,
          "wildcard_match match longer than pattern");

    /* leading wildcard — hits '*' immediately → always 1 for non-empty match */
    CHECK(wildcard_match("*", "anything") == 1,
          "wildcard_match star matches non-empty string");
    CHECK(wildcard_match("*.example.com", "sub.example.com") == 1,
          "wildcard_match star-dot prefix with sub-domain");
    CHECK(wildcard_match("*.example.com", "example.com") == 1,
          "wildcard_match star-dot prefix matches bare domain (prefix semantic)");

    /* prefix before wildcard */
    CHECK(wildcard_match("foo*", "foobar") == 1,
          "wildcard_match foo-star matches foobar");
    CHECK(wildcard_match("foo*", "barfoo") == 0,
          "wildcard_match foo-star rejects barfoo");
    CHECK(wildcard_match("foo*", "foo") == 0,
          "wildcard_match foo-star requires at least one char after prefix");
    CHECK(wildcard_match("example.*", "example.com") == 1,
          "wildcard_match example.star matches example.com");
    CHECK(wildcard_match("example.*", "other.com") == 0,
          "wildcard_match example.star rejects other.com");

    /* no match cases */
    CHECK(wildcard_match("abc", "ab") == 0,
          "wildcard_match pattern longer, no star");
    CHECK(wildcard_match("ab", "abc") == 0,
          "wildcard_match match longer, no star");
}

/* ── wildcard_matchn ──
 *
 * Like wildcard_match but only compares up to `num` characters.
 * Returns 1 when n reaches 0 (consumed all allowed chars without mismatch)
 * or when a '*' is encountered.
 */
static void test_wildcard_matchn(void)
{
    CHECK(wildcard_matchn("foobar", "foobar", 6) == 1,
          "wildcard_matchn n=6 full match");
    CHECK(wildcard_matchn("foobar", "foobaz", 5) == 1,
          "wildcard_matchn n=5 first 5 chars match");
    CHECK(wildcard_matchn("foobar", "foobaz", 6) == 0,
          "wildcard_matchn n=6 differ at last char");
    CHECK(wildcard_matchn("foo*", "foobar", 3) == 1,
          "wildcard_matchn n=3 hits star never (exhausted n first)");
    CHECK(wildcard_matchn("foo*", "foobar", 4) == 1,
          "wildcard_matchn n=4 hits star");
    CHECK(wildcard_matchn("abc", "xyz", 0) == 1,
          "wildcard_matchn n=0 always matches (no chars consumed)");
    CHECK(wildcard_matchn("", "", 5) == 1,
          "wildcard_matchn both empty");
}

/* ── hostname_isequal ── */
static void test_hostname_isequal(void)
{
    CHECK(hostname_isequal("example.com", "example.com") == 1,
          "hostname_isequal same lowercase");
    CHECK(hostname_isequal("EXAMPLE.COM", "example.com") == 1,
          "hostname_isequal upper vs lower");
    CHECK(hostname_isequal("Example.Com", "eXAMPLE.cOM") == 1,
          "hostname_isequal mixed case");
    CHECK(hostname_isequal("foo", "bar") == 0,
          "hostname_isequal different names");
    CHECK(hostname_isequal("foo.com", "foo.org") == 0,
          "hostname_isequal different TLD");
    CHECK(hostname_isequal("", "") == 1,
          "hostname_isequal both empty");
    CHECK(hostname_isequal("a", "a") == 1,
          "hostname_isequal single char same");
    CHECK(hostname_isequal("a", "b") == 0,
          "hostname_isequal single char different");
}

/* ── hostname_issubdomain ──
 *
 * Returns 2 when a == b (exact match from the right),
 *         1 when a is a proper subdomain of b,
 *         0 otherwise.
 * Comparison is case-insensitive and done right-to-left.
 */
static void test_hostname_issubdomain(void)
{
    CHECK(hostname_issubdomain("example.com", "example.com") == 2,
          "hostname_issubdomain exact match returns 2");
    CHECK(hostname_issubdomain("EXAMPLE.COM", "example.com") == 2,
          "hostname_issubdomain case-insensitive exact returns 2");
    CHECK(hostname_issubdomain("sub.example.com", "example.com") == 1,
          "hostname_issubdomain sub is subdomain");
    CHECK(hostname_issubdomain("deep.sub.example.com", "example.com") == 1,
          "hostname_issubdomain deep subdomain");
    CHECK(hostname_issubdomain("other.com", "example.com") == 0,
          "hostname_issubdomain unrelated domain");
    CHECK(hostname_issubdomain("com", "example.com") == 0,
          "hostname_issubdomain parent TLD is not a subdomain");
    CHECK(hostname_issubdomain("example.com", "sub.example.com") == 0,
          "hostname_issubdomain parent is not subdomain of child");
}

/* ── legal_hostname ──
 *
 * Returns 1 for names containing only [A-Za-z0-9._-] (where -/_ cannot start),
 * 0 otherwise.
 */
static void test_legal_hostname(void)
{
    CHECK(legal_hostname("example") == 1,
          "legal_hostname simple word");
    CHECK(legal_hostname("example.com") == 1,
          "legal_hostname with dot");
    CHECK(legal_hostname("foo-bar") == 1,
          "legal_hostname hyphen mid-word");
    CHECK(legal_hostname("foo_bar") == 1,
          "legal_hostname underscore mid-word");
    CHECK(legal_hostname("foo123") == 1,
          "legal_hostname trailing digits");
    CHECK(legal_hostname("123foo") == 1,
          "legal_hostname leading digits");
    CHECK(legal_hostname("foo bar") == 0,
          "legal_hostname rejects space");
    CHECK(legal_hostname("foo@bar") == 0,
          "legal_hostname rejects at-sign");
    CHECK(legal_hostname("-foo") == 0,
          "legal_hostname rejects leading hyphen");
    CHECK(legal_hostname("_foo") == 0,
          "legal_hostname rejects leading underscore");
}

/* ── main ── */
int main(void)
{
    test_wildcard_match();
    test_wildcard_matchn();
    test_hostname_isequal();
    test_hostname_issubdomain();
    test_legal_hostname();

    printf("%d passed\n", g_passed);
    if (g_failed > 0)
        printf("%d failed\n", g_failed);
    return g_failed > 0 ? 1 : 0;
}

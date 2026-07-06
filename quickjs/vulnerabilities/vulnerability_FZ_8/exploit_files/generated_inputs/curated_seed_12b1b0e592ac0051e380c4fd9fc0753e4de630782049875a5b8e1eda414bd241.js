function assert(actual, expected, message) {}

const a = 1;
var success = false;
var f = function () {
    eval("a = 1");
};
try {
    f();
} catch (e) {
    success = (e instanceof TypeError);
}
assert(success);
var __rx = /(ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|ab|cd)+/;
'abcdef'.match(__rx);

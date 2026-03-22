#!/bin/bash
# Write a standalone Node test runner for thrift.js (browser-only lib, no CommonJS exports)
cat > /tmp/run_thrift_tests.js << 'EOF'
const vm = require('vm');
const fs = require('fs');

// Load thrift.js into a sandbox (browser-only lib, sets Thrift global)
const code = fs.readFileSync('/src/thrift/lib/js/src/thrift.js', 'utf8');
const sandbox = { window: {}, XMLHttpRequest: function() {} };
vm.createContext(sandbox);
vm.runInContext(code, sandbox);
const Thrift = sandbox.Thrift;

let passed = 0, failed = 0;
function test(name, fn) {
  try { fn(); passed++; }
  catch(e) { console.error('FAIL:', name, '-', e.message); failed++; }
}
function expect(val) {
  return {
    toBe: (exp) => { if (val !== exp) throw new Error(`expected ${JSON.stringify(exp)}, got ${JSON.stringify(val)}`); },
    toEqual: (exp) => { if (JSON.stringify(val) !== JSON.stringify(exp)) throw new Error(`expected ${JSON.stringify(exp)}, got ${JSON.stringify(val)}`); },
  };
}

test('Thrift.Type.BOOL', () => expect(Thrift.Type.BOOL).toBe(2));
test('Thrift.Type.I32', () => expect(Thrift.Type.I32).toBe(8));
test('Thrift.Type.STRING', () => expect(Thrift.Type.STRING).toBe(11));
test('Thrift.Type.STRUCT', () => expect(Thrift.Type.STRUCT).toBe(12));
test('Thrift.Type.LIST', () => expect(Thrift.Type.LIST).toBe(15));
test('Thrift.MessageType.CALL', () => expect(Thrift.MessageType.CALL).toBe(1));
test('Thrift.MessageType.REPLY', () => expect(Thrift.MessageType.REPLY).toBe(2));
test('Thrift.MessageType.EXCEPTION', () => expect(Thrift.MessageType.EXCEPTION).toBe(3));
test('Thrift.MessageType.ONEWAY', () => expect(Thrift.MessageType.ONEWAY).toBe(4));
test('Thrift.objectLength empty', () => expect(Thrift.objectLength({})).toBe(0));
test('Thrift.objectLength two keys', () => expect(Thrift.objectLength({ a: 1, b: 2 })).toBe(2));
test('Thrift.inherits prototype chain', () => {
  function Base() {} Base.prototype.foo = function() { return 42; };
  function Child() {} Thrift.inherits(Child, Base);
  expect(new Child().foo()).toBe(42);
});
test('Thrift.copyList', () => expect(Thrift.copyList([1,2,3],[null])).toEqual([1,2,3]));
test('Thrift.copyMap', () => expect(Thrift.copyMap({a:1,b:2},[null])).toEqual({a:1,b:2}));
test('TException name', () => expect(new Thrift.TException('e').name).toBe('TException'));
test('TException message', () => expect(new Thrift.TException('e').message).toBe('e'));
test('TApplicationExceptionType.UNKNOWN', () => expect(Thrift.TApplicationExceptionType.UNKNOWN).toBe(0));
test('TApplicationExceptionType.WRONG_METHOD_NAME', () => expect(Thrift.TApplicationExceptionType.WRONG_METHOD_NAME).toBe(3));
test('TApplicationException round-trip via message envelope', () => {
  // TApplicationException(message, code); write uses struct; must wrap in message envelope to flush
  const t = new Thrift.Transport('/s'); const p = new Thrift.Protocol(t);
  p.writeMessageBegin('m', Thrift.MessageType.EXCEPTION, 1);
  new Thrift.TApplicationException('oops', Thrift.TApplicationExceptionType.UNKNOWN_METHOD).write(p);
  p.writeMessageEnd();
  const t2 = new Thrift.Transport('/s'); t2.setRecvBuffer(t.send_buf);
  const p2 = new Thrift.Protocol(t2); p2.readMessageBegin();
  const r = new Thrift.TApplicationException(); r.read(p2);
  expect(r.message).toBe('oops');
});
test('TProtocolExceptionType.UNKNOWN', () => expect(Thrift.TProtocolExceptionType.UNKNOWN).toBe(0));
test('TProtocolExceptionType.INVALID_DATA', () => expect(Thrift.TProtocolExceptionType.INVALID_DATA).toBe(1));
test('Transport write', () => {
  const t = new Thrift.Transport('/s'); t.write('hello'); expect(t.send_buf).toBe('hello');
});
test('Protocol readBool returns object with value', () => {
  // read functions return {value: ...} objects
  const t = new Thrift.Transport('/s'); const p = new Thrift.Protocol(t);
  p.writeMessageBegin('m', Thrift.MessageType.CALL, 1);
  p.writeStructBegin('S');
  p.writeFieldBegin('b', Thrift.Type.BOOL, 1); p.writeBool(true); p.writeFieldEnd();
  p.writeFieldBegin('i', Thrift.Type.I32, 2); p.writeI32(99); p.writeFieldEnd();
  p.writeFieldStop(); p.writeStructEnd();
  p.writeMessageEnd();
  const t2 = new Thrift.Transport('/s'); t2.setRecvBuffer(t.send_buf);
  const p2 = new Thrift.Protocol(t2); const h = p2.readMessageBegin();
  expect(h.fname).toBe('m'); expect(h.mtype).toBe(Thrift.MessageType.CALL);
  p2.readStructBegin();
  p2.readFieldBegin(); expect(p2.readBool().value).toBe(true); p2.readFieldEnd();
  p2.readFieldBegin(); expect(p2.readI32().value).toBe(99); p2.readFieldEnd();
});

console.log(passed + ' passed, ' + failed + ' failed');
EOF

node /tmp/run_thrift_tests.js 2>&1 | python3 /src/unit_tests/parse_results.py --framework pytest

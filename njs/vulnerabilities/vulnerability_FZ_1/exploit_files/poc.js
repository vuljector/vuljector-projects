try {
  var buf = Buffer.alloc(10);
  // Attempting to fill with an invalid encoding if possible,
  // or just exercising the path. 
  // njs_buffer_fill is often used internally during Buffer operations.
  buf.fill('test', 0, 10, 'invalid-encoding');
} catch (e) {}

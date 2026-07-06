({ 
  test: function() {
    try {
      return new RegExp("a").test("a");
    } catch (e) {
      return false;
    }
  }
})().test();

var __r = /(ab|cd)+/;

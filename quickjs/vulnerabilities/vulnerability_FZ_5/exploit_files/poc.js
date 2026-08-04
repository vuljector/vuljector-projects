for (var n=62;n<=68;n++){ try{ new RegExp("\\p{"+"A".repeat(n)+"}","u"); }catch(e){} }
print("done");

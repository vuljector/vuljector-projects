begin
  # Passing nil to Float() should normally raise a TypeError
  # With our patch, the nil check is bypassed, and it will likely crash or misbehave
  Float(nil)
rescue TypeError => e
  puts "CAUGHT_TYPE_ERROR: " + e.message
end

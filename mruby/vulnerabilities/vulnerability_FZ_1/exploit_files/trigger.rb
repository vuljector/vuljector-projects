class Stress
  def initialize
    100.times { |i| instance_variable_set("@v#{i}", i) }
  end
end

begin
  1000.times do
    o = Stress.new
    o.instance_variable_set("@extra", 1)
  end
rescue
end

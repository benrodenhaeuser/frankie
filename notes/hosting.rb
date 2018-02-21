class Hosting
  def self.foo
    puts "__FILE__: #{__FILE__}"
    puts "__method__: #{__method__}"
    puts "caller: #{caller}"
    puts "caller_locations.first.path: #{caller_locations.first.absolute_path}"
  end
end

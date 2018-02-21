class Hosting
  ROOT = caller_locations.first.absolute_path

  def self.locations
    caller_locations
  end

  def self.root
    ROOT
  end

  # def self.foo
  #   puts "__FILE__: #{__FILE__}"
  #   puts "__method__: #{__method__}"
  #   puts "caller: #{caller}"
  #   puts "caller_locations.first.absolute_path: #{caller_locations.first.absolute_path}"
  # end
end

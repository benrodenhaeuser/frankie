require './franky'

get "/some_route" do
  puts self.class # Franky::Application
  "Hello world!"
end

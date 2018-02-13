require './frankie'

get "/some_route" do
  @name = 'Franky'
  erb :hello
end

# get "/some_route/:some_id" do
#   # handle pattern
# end

require './franky'

get "/some_route" do
  @name = 'Franky'
  erb :hello
end

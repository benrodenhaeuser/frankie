require './frankie'

get "/some_route" do
  @name = 'Franky'
  erb :hello
end

get "/some_route/:some_id/" do
  "captured #{params['some_id']}"
end

get "/some_route/:some_id/todo/:some_other_id" do
  "captured #{params['some_id']} and #{params['some_other_id']}"
end

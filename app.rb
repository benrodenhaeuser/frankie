require './frankie'
require "tilt/erubis"

get "/some_route" do
  @name = 'Frankie'
  erb :hello
end

get "/segment/:some_id/" do
  "captured #{params['some_id']}"
end

get "/segment/:some_id/segment/:some_other_id" do
  "captured #{params['some_id']} and #{params['some_other_id']}"
end

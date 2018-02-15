require_relative './frankie'
require "tilt/erubis"

get "/" do
  "hello world"
end

get "/frankie_says_hello" do
  @name = 'Frankie'
  erb :hello
end

get "/segment/:some_id/segment/:some_other_id" do
  "Frankie has captured #{params['some_id']} and #{params['some_other_id']}."
end

post "/add_todo" do
  @string = params[:submitted_string]
  # store the string in some file?
  redirect "/"
end

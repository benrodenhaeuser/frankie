require_relative 'frankie'

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

get "/something" do
  redirect "/"
  puts "This will never be printed"
end

post "/snippet" do
  redirect "/frankie_says_hello"
end

# app.rb

require_relative 'frankie'

get '/' do
  'hello world'
end

get '/ditty' do
  @my_way = 'my way'
  erb(:ditty)
end

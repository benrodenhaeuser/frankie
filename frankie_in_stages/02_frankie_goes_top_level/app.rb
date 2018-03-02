# app.rb

require_relative 'frankie'

get '/' do
  'frankie says hello.'
end

get '/ditty' do
  @my_way = 'my way'
  erb(:ditty)
end

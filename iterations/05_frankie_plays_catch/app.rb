# app.rb

require_relative 'frankie'

get '/' do
  'frankie says hello.'
end

get '/ditty' do
  @my_way = 'my way'
  erb(:ditty)
end

get '/:album/:song' do
  "I will sing '#{params['song']}' from '#{params['album']}' for you."
end

# app.rb

require_relative 'frankie'

use Rack::Session::Cookie, :key => 'rack.session', :secret => "secret"

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

get '/set_message' do
  session[:message] = 'hello from frankie session.'
  redirect '/'
end

get '/get_message' do
  if session[:message]
    session.delete(:message)
  else
    "there is no message"
  end
end

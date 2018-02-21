require_relative '../../frankie'

require 'erb'
require 'yaml'

use Rack::Session::Cookie, :key => 'rack.session', :secret => "secret"

def data_file
  if ENV["RACK_ENV"] == "test"
    File.expand_path('../test/data/quotes.yml', __FILE__)
  else
    File.expand_path('../data/quotes.yml', __FILE__)
  end
end

def insert(author, quote, quotes)
  next_id = quotes['next_id']
  quotes[next_id] = { "author" => author, "quote" => quote }
  quotes['next_id'] += 1
end

get "/" do
  redirect "/quotes"
end

get "/quotes" do
  @quotes = YAML.load(File.read(data_file))
  erb :index
end

get "/quotes/new" do
  erb :new_quote
end

post "/quotes" do
  author, quote = params['author'], params['quote']
  quotes = YAML.load(File.read(data_file))
  insert(author, quote, quotes)
  File.open(data_file, "w") { |file| file.write(quotes.to_yaml) }
  session[:message] = 'The quote has been added.'
  redirect "/quotes"
end

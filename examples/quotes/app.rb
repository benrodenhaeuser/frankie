require_relative '../../frankie'
require 'yaml'

get "/" do
  redirect "/quotes"
end

# show list of quotes
get "/quotes" do
  @quotes = YAML.load(File.read("./data/quotes.yml"))
  headers["Content-Type"] = "text/html" # shouldn't this be done by frankie?
  erb :index
end

# form for adding a new quote
get "/quotes/new" do
  headers["Content-Type"] = "text/html" # shouldn't this be done by frankie?
  erb :new_quote
end

# update list of quotes
post "/quotes" do
  author = params['author']
  quote = params['quote']
  quotes = YAML.load(File.read("./data/quotes.yml"))
  next_id = quotes['next_id']
  quotes[next_id] = { "author" => author, "quote" => quote }
  quotes['next_id'] += 1
  File.open("./data/quotes.yml","w") { |file| file.write(quotes.to_yaml) }
  redirect "/quotes"
end

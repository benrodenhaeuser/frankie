require 'yaml'

# load data into hash table

data = YAML.load(File.read("./data/quotes.yml"))

# access hash table

p data
p data[1]['author']
p data[1]['quote']

data[4] == { "author" => "Beckenbauer", "quote" => "Schau mer mal"}

data[5] == { "author" => "Some author", "quote" => "Some quote"}

# add a new entry

data[data["next_id"]] = { "author" => "famous person", "quote" => "whatever" }

# increase next id by one

data["next_id"] += 1

# save hash as yaml to file

File.open("./data/quotes.yml","w") do |file|
   file.write(data.to_yaml)
end

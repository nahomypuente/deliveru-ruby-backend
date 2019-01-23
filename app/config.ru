#\ -p 4000

require 'rack-proxy'
require 'sinatra'
require './app'

## Function to load all instances of model_class from the json file.
def load_model(model_class)
  begin
    file_content = File.read(model_class.db_filename)
    json_data = JSON.parse(file_content)
  rescue Errno::ENOENT
    # The file does not exists
    json_data = []
  end
  json_data.each do |data_hash|
    new_object = model_class.from_hash(data_hash)
    new_object.save
  end
end

warmup do
  puts 'Loading objects from json files'
  # TODO: load the models from the json files. This tasks executes after
  # the server is loaded. Use the function load_model defined above.
end

# Setting up routes
ROUTES = {
  '/' => DeliveruApp
}

# Run the application
run Rack::URLMap.new(ROUTES)

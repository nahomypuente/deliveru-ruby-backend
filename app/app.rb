require 'json'
require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/namespace'

# Main class of the application
class DeliveruApp < Sinatra::Application
  register Sinatra::Namespace

  enable :sessions unless test?

  ## Function to clean up the json requests.
  before do
    begin
      if request.body.read(1)
        request.body.rewind
        @request_payload = JSON.parse(request.body.read, symbolize_names: true)
      end
    rescue JSON::ParserError
      request.body.rewind
      puts "The body #{request.body.read} was not JSON"
    end
  end

  register do
    def auth
      condition do
        halt 401 unless session.key?(:logged_id) || self.settings.test?
      end
    end
  end

  ## API functions
  namespace '/api' do
    # TODO program API get and post calls.
    # ...

    get '*' do
      halt 404
    end
  end

  # This goes last as it is a catch all to redirect to the React Router
  get '/*' do
    erb :index
  end
end

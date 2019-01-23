ENV['RACK_ENV'] = 'test'

require 'test/unit'
require 'rack/test'
require 'json'
require_relative '../app'
require_relative '../models/user'

# Base test class with auxiliary functions. Do not run directly
class BaseAppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    DeliveruApp
  end

  # Auxiliar functions
  def get_registered_number(api_url, content = {})
    get api_url, content, format: 'json'
    unless last_response.ok?
      return 0
    end
    JSON.parse(last_response.body).size
  end

  def register_default_provider
    post 'api/providers', @default_provider.to_json
    assert last_response.ok?, last_response.status.to_s
    last_response.body.to_i
  end

  def register_default_consumer
    post 'api/consumers', @default_consumer.to_json
    assert last_response.ok?, last_response.status.to_s
    last_response.body.to_i
  end

  # Functions to set up the environment before and after each test
  def setup
    # Define some dummy objects
    @default_provider = { email: 'provider@provider.com', location: 1,
                          password: '1234', store_name: 'My Pretty Store',
                          max_delivery_distance: 5.6 }
    @default_consumer = { email: 'consumer@consumer.com', location: 2,
                          password: '1234' }
    @default_items = [
      { name: 'Item1', price: 39.99, provider: @default_provider[:id] },
      { name: 'Item2', price: 10, provider: @default_provider[:id] },
      { name: 'Expensive Item', price: 399.99, provider: 3 }
    ]

    # Necessary because of the Sinatra::Reloader module in app
    app.settings.root = Dir.pwd

    # Check everything is empty
    assert_equal(0, get_registered_number('api/consumers'),
                 'There are registered consumers at test setup')
    assert_equal(0, get_registered_number('api/providers'),
                 'There are registered providers at test setup')
    # No logged user
    session = {}
    get '/', 'rack.session' => session
    assert_equal(nil, session[:logged_id])

    # TODO: Rename the json files
    # The best thing to do is to use mocks.
    Provider.db_filename = 'tests/test_files/test_providers.json'
    Consumer.db_filename = 'tests/test_files/test_consumers.json'
  end

  def teardown
    # Remove default users. Does not fail if the users are not present.
    get 'api/consumers', format: 'json'
    JSON.parse(last_response.body).each do |consumer|
      post "api/users/delete/#{consumer['id']}"
    end
    get 'api/providers', format: 'json'
    JSON.parse(last_response.body).each do |provider|
      post "api/users/delete/#{provider['id']}"
    end
  end
end

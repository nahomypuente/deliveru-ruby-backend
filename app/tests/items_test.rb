ENV['RACK_ENV'] = 'test'

require 'json'
require_relative 'base_test'
require_relative '../app'
require_relative '../models/item'

# TestSuite for the API methods of DeliveruApp related to item management
class ItemAppTest < BaseAppTest
  # Auxiliary functions
  def register_default_items
    @default_items.values.each do |item|
      post 'api/items', item.to_json
      assert last_response.ok?, "Response with code #{last_response.status}"
    end
  end

  # Functions to set up the environment before and after each test
  def setup
    super
    @default_provider_id = register_default_provider

    # Define some dummy items
    @default_items = {
      'Item2' => { name: 'Item2', price: 10, provider: @default_provider_id },
      'Item1' => { name: 'Item1', price: 39.99, provider: @default_provider_id }
    }

    # Check everything is empty
    assert_equal(0, get_registered_number('api/items'),
                 'There are registered items at test setup')
    # TODO: Rename the json files
    Item.db_filename = 'tests/test_files/test_items.json'
  end

  def teardown
    # Delete all the items. It should never fail
    get 'api/items', :provider => @default_provider_id, format: 'json'
    JSON.parse(last_response.body).each do |item|
      post "api/items/delete/#{item['id']}"
    end
    super
  end

  # Test cases
  def test_add_items
    register_default_items

    get 'api/items', :provider => @default_provider_id
    assert last_response.ok?, last_response.body
    response = JSON.parse(last_response.body)
    assert_equal @default_items.size, response.size, 'Wrong number of items'

    # Check all the fields for every item
    response.each do |item_hash|
      assert_not_nil item_hash['id'], 'Item id is null'
      item_name = item_hash['name']
      assert @default_items.key?(item_name), item_hash.to_s
      original_item = @default_items[item_name]
      assert_equal original_item[:price], item_hash['price'], 'Bad price'
      assert_equal(original_item[:provider], item_hash['provider'],
                   'Bad provider')
    end
  end

  def test_add_duplicate_name_and_provider
    register_default_items

    item_hash = @default_items.values[0]
    post 'api/items', item_hash.to_json
    assert_equal last_response.status, 409, last_response.body
  end

  def test_get_item_non_existing_provider
    get 'api/items', provider: 200
    assert_equal last_response.status, 404, last_response.body
  end
end

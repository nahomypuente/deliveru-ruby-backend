ENV["RACK_ENV"] = "test"

require "json"
require_relative "items_test"

# TestSuite for the API methods of DeliveruApp related to item management
class ItemAppErrorTest < ItemAppTest
  # Adding two items with the same name but different provider should not fail.
  def test_add_duplicate_name
    register_default_items

    # Register a new provider
    provider_payload = @default_provider.dup
    provider_payload[:email] = "provider1@provider.com"
    provider_payload[:store_name] = "New Store"
    post "api/providers", provider_payload.to_json
    provider_id = last_response.body.to_i
    assert last_response.ok?, last_response.status.to_s

    payload = @default_items.values[0].dup
    payload[:provider] = provider_id
    post "api/items", payload.to_json
    assert_equal 3, get_registered_number("api/items"), "Wrong number of items."
  end

  def test_add_item_non_existing_provider
    payload = @default_items.values[0].dup
    payload[:provider] = 300
    post "api/items", payload.to_json
    assert_equal last_response.status, 404, last_response.body
    assert_equal(0, get_registered_number("api/items"),
                 "Item was registered with non exiting provider.")
  end

  def test_add_item_missing_params
    post "api/items", { name: "Item1", price: 39.99 }.to_json # No provider
    assert_equal last_response.status, 400, last_response.body
    assert_equal(0, get_registered_number("api/items"),
                 "Item was registered with missing provider.")

    post "api/items", { price: 39.99, # No name
                        provider: @default_provider_id }.to_json
    assert_equal last_response.status, 400, last_response.body

    post "api/items", { name: "Item1", # No price
                        provider: @default_provider_id }.to_json
    assert_equal last_response.status, 400, last_response.body
    assert_equal(0, get_registered_number("api/items"),
                 "Item was registered with missing price.")
  end
end

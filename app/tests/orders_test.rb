ENV["RACK_ENV"] = "test"

require "json"
require_relative "base_test"
require_relative "../app"

ORDER_PAYED = 'payed'.freeze
ORDER_DELIVERED = 'delivered'.freeze
ORDER_FINISHED = 'finished'.freeze

# TestSuite for the API methods of DeliveruApp related to item management
class OrdersAppTest < BaseAppTest
  # Auxiliary functions
  def register_default_items
    ids = []
    @default_items.each do |item|
      post "api/items", item.to_json
      assert last_response.ok?, "Response with code #{last_response.status}"
      ids << last_response.body.to_i
    end
    ids
  end

  def count_orders
    get_registered_number("api/orders", user_id: @default_consumer_id) +
      get_registered_number("api/orders", user_id: @default_provider_id)
  end

  # Functions to set up the environment before and after each test
  def setup
    super
    @default_provider_id = register_default_provider
    @default_consumer_id = register_default_consumer

    # Define some dummy items
    @default_items = [
      { name: "Item1", price: 39.99, provider: @default_provider_id },
      { name: "Item2", price: 10, provider: @default_provider_id }
    ]

    # Check everything is empty
    assert_equal(0, get_registered_number("api/items"),
                 "There are registered items at test setup")

    assert_equal 0, count_orders, "There are registered orders at test setup"

    # TODO: Rename the files
    Item.db_filename = "tests/test_files/test_items.json"
    Order.db_filename = "tests/test_files/test_orders.json"
  end

  def teardown
    # Delete all the items. It should never fail
    get "api/items", format: "json"
    JSON.parse(last_response.body).each do |item|
      post "api/items/delete/#{item["id"]}"
    end

    # Delete all the orders. It should never fail
    get "api/orders", { user_id: @default_provider_id }, format: "json"
    JSON.parse(last_response.body).each do |order|
      post "api/orders/delete/#{order["id"]}"
    end

    get "api/orders", { user_id: @default_consumer_id }, format: "json"
    JSON.parse(last_response.body).each do |order|
      post "api/orders/delete/#{order["id"]}"
    end
    super
  end

  def test_post_order
    item_ids = register_default_items

    payload = { provider: @default_provider_id,
                consumer: @default_consumer_id,
                items: [
                  { id: item_ids[0].to_i, amount: 2 }
                ] }
    post "api/orders", payload.to_json
    assert(last_response.ok?,
           "Post order failed with code #{last_response.status}")

    get "api/orders", { user_id: @default_consumer_id }, format: "json"
    orders = JSON.parse(last_response.body)
    assert_equal(1, orders.size, "Wrong number of orders")

    order_hash = orders[0]
    assert_equal @default_consumer_id, order_hash["consumer"], "Wrong consumer"
    assert_equal(@default_consumer[:location], order_hash["consumer_location"],
                 "Wrong consumer location")
    assert_equal @default_provider_id, order_hash["provider"], "Wrong provider"
    assert_equal(@default_provider[:store_name], order_hash["provider_name"],
                 "Wrong provider")
    assert_equal ORDER_PAYED, order_hash["status"], "Wrong status"
    assert_equal(2 * @default_items[0][:price], order_hash["order_amount"],
                 "Wrong order amount")
  end

  def test_order_detail
    registered_item_ids = register_default_items

    payload = { provider: @default_provider_id,
                consumer: @default_consumer_id,
                items: [
                  { id: registered_item_ids[0].to_i, amount: 2 },
                  { id: registered_item_ids[1].to_i, amount: 1 }
                ] }
    post "api/orders", payload.to_json
    returned_order_id = last_response.body.to_i
    assert_not_nil returned_order_id, "Order id returned is null"

    get "api/orders/detail/#{returned_order_id}", format: "json"
    assert(last_response.ok?,
           "Order detail get failed with code #{last_response.status}")
    order_items = JSON.parse(last_response.body)
    assert_equal(2, order_items.size, "Wrong number of items")

    order_items.each do |item_hash|
      item_id = item_hash["id"]
      item = Item.find(item_id)
      assert_equal item.name, item_hash["name"], "Wrong item name"
      assert_equal item.price, item_hash["price"], "Wrong item price"
      index = registered_item_ids.index(item_id)
      assert_not_nil index, "Item in detail does not exists"
      if index.zero?
        assert_equal 2, item_hash["amount"], "Wrong number of items"
      else
        assert_equal 1, item_hash["amount"], "Wrong number of items"
      end
    end
  end

  def test_post_order_non_existing_users
    item_ids = register_default_items

    payload = { provider: 300, consumer: @default_consumer_id,
                items: [{ id: item_ids[0].to_i, amount: 2 }] }
    post "api/orders", payload.to_json
    assert_equal 404, last_response.status

    payload = { provider: @default_provider_id, consumer: 300,
                items: [{ id: item_ids[0].to_i, amount: 2 }] }
    post "api/orders", payload.to_json
    assert_equal 404, last_response.status

    payload = { provider: @default_provider_id, consumer: @default_consumer_id,
                items: [{ id: 300, amount: 2 }] }
    post "api/orders", payload.to_json
    assert_equal 404, last_response.status

    assert_equal(0, count_orders,
                 "Order registered with non existing users or items")
  end

  def test_get_order_non_existing_users
    get "api/orders", {user_id: 300}
    assert_equal 404, last_response.status
  end

  def test_post_order_check_balances
    item_ids = register_default_items

    payload = { provider: @default_provider_id,
                consumer: @default_consumer_id,
                items: [{ id: item_ids[0].to_i, amount: 2 }] }
    expected_total = 2 * @default_items[0][:price]
    post "api/orders", payload.to_json
    assert last_response.ok?

    get "api/users/#{@default_provider_id}", format: "json"
    response = JSON.parse(last_response.body)
    assert_equal(expected_total, response["balance"],
                 "Order amount not added to provider balance")

    get "api/users/#{@default_consumer_id}", format: "json"
    response = JSON.parse(last_response.body)
    assert_equal(expected_total * -1, response["balance"],
                 "Order amount not subtracted to consumer balance")
  end

  def test_deliver_order
    item_ids = register_default_items

    payload = { provider: @default_provider_id,
                consumer: @default_consumer_id,
                items: [{ id: item_ids[0].to_i, amount: 2 }] }
    post "api/orders", payload.to_json
    assert last_response.ok?
    returned_order_id = last_response.body.to_i

    post "api/deliver/#{returned_order_id}"
    assert last_response.ok?

    # Get the order to see if the state has changed
    get "api/orders", { user_id: @default_provider_id }, format: "json"
    orders = JSON.parse(last_response.body)
    assert_equal(1, orders.size, "Wrong number of orders")
    order_hash = orders[0]
    assert_equal(ORDER_DELIVERED, order_hash["status"],
                 "Wrong order status after delivery")
  end

  def test_deliver_non_existing_order
    post "api/deliver/300"
    assert_equal 404, last_response.status
  end
end

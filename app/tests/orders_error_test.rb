require_relative "orders_test"

# TestSuite for the API methods of DeliveruApp related to item management
class OrdersAppErrorTest < OrdersAppTest
  def test_post_order_missing_params
    item_ids = register_default_items

    payload = { consumer: @default_consumer_id, # No provider
                items: [{ id: item_ids[0].to_i, amount: 2 }] }
    post "api/orders", payload.to_json
    assert_equal 400, last_response.status

    payload = { provider: @default_provider_id, # No consumer
                items: [{ id: item_ids[0].to_i, amount: 2 }] }
    post "api/orders", payload.to_json
    assert_equal 400, last_response.status

    payload = { provider: @default_provider_id,
                consumer: @default_consumer_id,
                items: [] } # No items
    post "api/orders", payload.to_json
    assert_equal 400, last_response.status
  end

  def test_get_order_no_user_id
    get "api/orders"
    assert_equal 400, last_response.status
  end

  def test_deliver_no_order_id
    post "api/deliver/"
    assert_equal 404, last_response.status
  end
end

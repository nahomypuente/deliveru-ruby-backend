ENV["RACK_ENV"] = "test"

require "json"
require_relative "base_test"
require_relative "../app"
require_relative "../models/user"

# TestSuite for the API methods of DeliveruApp related to user management
class UserAppTest < BaseAppTest
  # Tests cases
  def test_register_consumer
    id = register_default_consumer

    get "api/consumers", format: "json"
    response = JSON.parse(last_response.body)
    assert_equal 1, response.size,
                 "Wrong number of registered consumers"
    assert_equal @default_consumer[:email], response[0]["email"],
                 "Bad email"
    assert_equal @default_consumer[:location], response[0]["location"],
                 "Bad location"
    assert_equal id, response[0]["id"], "Bad id #{id}"
  end

  def test_register_existing_consumer
    register_default_consumer

    post "api/consumers", @default_consumer.to_json
    assert_equal last_response.status, 409, last_response.body
  end

  def test_register_provider
    id = register_default_provider

    get "api/providers", format: "json"
    response = JSON.parse(last_response.body)
    assert_equal 1, response.size, "Wrong number of registered providers"
    assert_equal id, response[0]["id"], "Bad id #{id}"
    assert_equal @default_provider[:email], response[0]["email"],
                 "Bad email"
    assert_equal @default_provider[:location], response[0]["location"],
                 "Bad location"
    assert_equal @default_provider[:store_name], response[0]["store_name"],
                 "Bad store_name"
    assert_equal @default_provider[:max_delivery_distance],
                 response[0]["max_delivery_distance"], "Bad delivery distance"
  end

  def test_register_existing_provider
    register_default_provider

    post "api/providers", @default_provider.to_json
    assert_equal last_response.status, 409, last_response.body
  end

  def test_register_crossed_email
    register_default_consumer

    post "api/providers", @default_consumer.to_json
    assert_equal last_response.status, 409, last_response.body
  end

  def test_login_registered
    id = register_default_provider

    session = {}
    payload = { email: @default_provider[:email], password: "1234" }
    post "api/login", payload.to_json, "rack.session" => session
    assert last_response.ok?, last_response.body
    assert_equal id, session[:logged_id]
  end

  def test_login_no_registered
    payload = { email: @default_provider[:email], password: "1234" }
    session = {}
    post "api/login", payload.to_json, "rack.session" => session
    assert_equal last_response.status, 401, last_response.body
    assert_equal(nil, session[:logged_id])
  end

  def test_user_details
    id = register_default_consumer

    get "api/users/#{id}", format: "json"
    assert last_response.ok?
    response = JSON.parse(last_response.body)

    assert_equal @default_consumer[:email], response["email"],
                 "Bad email"
    assert_equal 0, response["balance"], "Bad starting balance"
  end

  def test_user_details_non_existing
    get "api/users/300", format: "json"
    assert_equal last_response.status, 404
  end
end

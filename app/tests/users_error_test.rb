ENV["RACK_ENV"] = "test"

require "json"
require_relative "users_test"

# TestSuite for the API methods of DeliveruApp related to user management
class UserAppErrorTest < UserAppTest

  def test_register_consumer_incomplete
    register_default_consumer

    post "api/consumers", { location: 1 }.to_json # request without email
    assert_equal last_response.status, 400, last_response.body

    post "api/consumers", { email: "a" }.to_json # request without location
    assert_equal last_response.status, 400, last_response.body
  end

  def test_register_provider_incomplete
    register_default_provider

    post "api/providers", { location: "a", store_name: "a" }.to_json
    assert_equal last_response.status, 400, last_response.body

    post "api/providers", { email: "a", store_name: "a" }.to_json
    assert_equal last_response.status, 400, last_response.body

    post "api/providers", { email: "a", location: "a" }.to_json
    assert_equal last_response.status, 400, last_response.body
  end

  def test_user_details_no_user_id
    get "api/users", format: "json"
    assert_equal last_response.status, 404
  end
end
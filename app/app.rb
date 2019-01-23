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
        ##Convierte una cadena de la notación de objetos de JavaScript (JSON)
        ## en un objeto
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
    post '/login' do
      email = @request_payload[:email]
      password = @request_payload[:password]
      hash_user = {"email" => email}
      if Consumer.exists?(hash_user)
        instances = Consumer.filter(hash_user)
				session[:logged_id] = instances[0].id
        passw = instances[0].to_hash["password"]
        isProvider = false
      elsif Provider.exists?(hash_user)
        instances = Provider.filter(hash_user)
				session[:logged_id] = instances[0].id
        passw = instances[0].to_hash["password"]
        isProvider = true
      else
        halt 401
      end
      if passw != password
          halt 403
      end
      result = {"id"=>instances[0].id , "isProvider"=> isProvider}
      result.to_json
    end

    post '/logout' do
      result = {}
      result.to_json
    end

    post '/consumers' do
      email = @request_payload[:email]
      location = @request_payload[:location]
      password = @request_payload[:password]
      hash_user = {"email"=>email}
      if email.nil? || location.nil?
        halt 400
      end
      if Provider.exists?(hash_user)
        halt 409
      elsif Consumer.exists?(hash_user)
        halt 409
      end
      user = Consumer.new
      user.email = email
      user.location = location
      user.password = password
      user.balance = 0.0
      user.save
      user.id.to_json
    end

    post '/providers' do
      email = @request_payload[:email]
      store_name = @request_payload[:store_name]
      location = @request_payload[:location]
      password = @request_payload[:password]
      max_delivery_distance = @request_payload[:max_delivery_distance]
      hash_user = {"email"=>email}
      if email.nil? || location.nil? || store_name.nil?
        halt 400
      end
      if Provider.exists?(hash_user)
        halt 409
      end
      if Consumer.exists?(hash_user)
        halt 409
      end
      user = Provider.new
      user.email = email
      user.location = location
      user.password = password
      user.store_name = store_name
      user.max_delivery_distance = max_delivery_distance
      user.balance = 0.0
      user.save
      user.id.to_json
    end

    post '/items' do
      name = @request_payload[:name]
      price = @request_payload[:price]
      provider = @request_payload[:provider]
      if name.nil? || price == 0 || provider.nil?
        halt 400
      end
      unless Provider.index?(provider)
        halt 404
      end
      item_hash = {"name"=>name,"provider"=>provider}
      if Item.exists?(item_hash)
        halt 409
      end
      item = Item.new
      item.name = name
      item.price = price
      item.provider = provider
      item.save
      item.id.to_json
    end

    post '/items/delete/:id' do
      id = @params[:id].to_i
      unless Item.index?(id)
        halt 404
      end
      user_id = session[:logged_id]
      if Item.exists?({"id"=> id,"provider"=>user_id})
        Item.delete(id)
        Item.save
      else
       halt 403
      end
    end

    get '/providers' do
      location = params[:location]
      if location.nil?
        providers = Provider.all
      else
        location = location.to_i
      end
      hash_location = {"location"=>location}
      if Location.index?(location)
        providers = Provider.filter(hash_location)
      else
        halt 404
      end
      json_response = []
      providers.each do |provider|
        json_response << provider.to_hash
      end
      json json_response
    end

    get '/consumers' do
    consumers = Consumer.all
    json_response = []
    consumers.each do |consumer|
      json_response << consumer.to_hash
    end
    json json_response
    end

    post '/users/delete/:id' do
      id = @params[:id].to_i
      if Provider.index?(id)
        Provider.delete(id)
        Provider.save
      elsif Consumer.index?(id)
        Consumer.delete(id)
        Consumer.save
      else
        halt 404
      end
    end

    get '/items' do
      provider = params[:provider]
      unless provider.nil?
        provider = provider.to_i
      end
      hash_provider = {"provider"=>provider}
      unless Provider.index?(provider)
        halt 404
      end
      items = Item.filter(hash_provider)
      json_response = []
      items.each do |item|
        json_response << item.to_hash
      end
      json json_response
    end

    post '/orders' do
      provider = @request_payload[:provider]
      items = @request_payload[:items]
      consumer = @request_payload[:consumer]
      if provider.nil? || consumer.nil?
        halt 400
      else
        provider = provider.to_i
        consumer = consumer.to_i
      end
      unless Provider.index?(provider) || Consumer.index?(consumer)
        halt 400
      end
      items.each do |item|
        if item[:id].nil?
          halt 400
        end
        if not Item.index?(item[:id].to_i)
          halt 404
        end
      end

      order = Order.new
      amount = 0
      order.order_amount = amount.to_f
      order.provider = provider
      order.items = items
      order.total_item
      order.consumer = consumer
      order.pay
      order.total_order
      object_provider = Provider.find(provider)
      object_provider.save_balance(order.order_amount)
      Provider.save
      object_consumer = Consumer.find(consumer)
      object_consumer.save_balance(order.order_amount)
      Consumer.save
      order.save
      order.id.to_json
    end

    get '/orders/detail/:id' do
      id = @params[:id]
      if id.nil?
        halt 400
      else
        id = id.to_i
      end
      unless Order.index?(id)
        halt 404
      end
      order_object = Order.find(id)
      json_response = []
      order_object.items.each do |item|
        id_item = item["id"]
        item_object = Item.find(id_item)
        item_hash = item_object.to_hash
        item_hash["amount"] = item["amount"]
        json_response << item_hash
      end
      json json_response
    end

    get '/orders' do
      user_id = params[:user_id]
      if user_id.nil?
        halt 400
      else
        user_id = user_id.to_i
      end
      if Consumer.index?(user_id)
        object_consumer = Consumer.find(user_id)
        email_consumer = object_consumer.email
        location_consumer = object_consumer.location
        hash_consumer = {"consumer"=>user_id}
        list_order = Order.filter(hash_consumer)
        json_response = []

        list_order.each do |order|
          id_order = order.id
          id_provider = order.provider
          object_provider = Provider.find(id_provider)
          name_provider = object_provider.store_name
          hash_user = Hash.new
          hash_user["id"] = id_order
          hash_user["provider"] = id_provider
          hash_user["provider_name"] = name_provider
          hash_user["consumer"] = user_id
          hash_user["consumer_email"] = email_consumer
          hash_user["consumer_location"] = location_consumer
          hash_user["order_amount"] = order.order_amount
          hash_user["status"] = order.status
          json_response << hash_user
        end
      elsif Provider.index?(user_id)
        object_provider = Provider.find(user_id)
        hash_provider = {"provider"=>user_id}
        store_name_provider = object_provider.store_name
        list_order = Order.filter(hash_provider)
        json_response = []

        list_order.each do |order|
          id_order = order.id
          id_consumer = order.consumer
          unless Consumer.index?(id_consumer)
            halt 404
          end
          object_consumer = Consumer.find(id_consumer)
          email_consumer = object_consumer.email
          location_consumer = object_consumer.location
          hash_user = Hash.new
          hash_user["id"] = id_order
          hash_user["provider"] = user_id
          hash_user["provider_name"] = store_name_provider
          hash_user["consumer"] = id_consumer
          hash_user["consumer_email"] = email_consumer
          hash_user["consumer_location"] = location_consumer
          hash_user["order_amount"] = order.order_amount
          hash_user["status"] = order.status
          json_response << hash_user
        end
      end
      json json_response
    end

    post '/deliver/:id' do
      id = @params[:id].to_i
      if Order.index?(id)
        object_order = Order.find(id)
        object_order.deliver
        Order.save
      else
        halt 404
      end
    end

    post '/orders/delete/:id' do
      id = @params[:id].to_i
      Order.delete(id)
      Order.save
    end

    get '/users/:id' do
      id = @params[:id]
      if id.nil?
        halt 400
      else
        id = id.to_i
      end
      if Consumer.index?(id)
        user = Consumer.find(id)
        user_hash = user.to_hash
        return_user = Hash.new
      elsif Provider.index?(id)
        user = Provider.find(id)
        user_hash = user.to_hash
        return_user = Hash.new
        return_user["store_name"] = user_hash["store_name"]
      else
        halt 404
      end
      return_user["email"] = user_hash["email"]
      return_user["balance"] = user_hash["balance"]
      return_user.to_json
    end

    get '/locations' do
      locations = Location.all
      json_response = []
      locations.each do |location|
        json_response << location.to_hash
      end
      json json_response
    end

    get '*' do
      halt 404
    end
  end
# This goes last as it is a catch all to redirect to the React Router
  get '/*' do
    erb :index
  end
end

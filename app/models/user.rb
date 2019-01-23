require 'json'
require './models/model'
class User < Model
  attr_accessor :email, :location, :password , :balance
  @db_filename = 'user.json'

  def self.validate_hash(model_hash)
    model_hash.key?('email') && model_hash.key?('location') &&
    model_hash.key?('password') && model_hash.key?('balance') && super
  end
  def save_balance(total)
    @balance  = @balance - total
  end
end

class Provider < User
  @db_filename = 'provider.json'
  attr_accessor :store_name , :max_delivery_distance , :rate
  def self.validate_hash(model_hash)
    model_hash.key?('store_name') && model_hash.key?('max_delivery_distance') &&
    super
  end
  def save_balance(total)
    @balance  = @balance + total
  end
end

class Consumer < User
  @db_filename = 'consumer.json'
end

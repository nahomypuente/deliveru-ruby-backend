require 'json'
require './models/model'

class Item < Model
  @db_filename = 'item.json'
  attr_accessor :name, :price ,:provider

  def self.validate_hash(model_hash)
    model_hash.key?('name') && model_hash.key?('price') &&
    model_hash.key?('provider') && super
  end

  def sacar_total(amount)
      total_item = @price * amount
      total_item
  end
end

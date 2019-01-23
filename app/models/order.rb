require 'json'
require './models/model'
require './models/item'

class Order < Model
  @db_filename = 'order.json'
  attr_accessor :consumer, :items, :provider, :order_amount, :status

  def self.validate_hash(model_hash)
    model_hash.key?('consumer') && model_hash.key?('items') &&
    model_hash.key?('provider') && model_hash.key?('order_amount') &&
    model_hash.key?('status') && super
  end
  def total_item
    @items.each do |item|
      object_item = Item.find(item[:id].to_i)
      total_item = object_item.sacar_total(item[:amount].to_f)
      item[:total_item] = total_item
    end
  end
  def total_order
    #itero cada item de la orden para sumar el total de la orden
    @items.each do |item|
      @order_amount = @order_amount + item[:total_item].to_f
    end
  end
  def deliver
    @status = :delivered
  end
  def pay
    @status = :payed
  end
  def finish
    @status = :finished
  end
end

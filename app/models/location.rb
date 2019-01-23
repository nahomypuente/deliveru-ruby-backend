require 'json'
require './models/model'

class Location < Model
  @db_filename = 'location.json'
  attr_accessor :name

  def self.validate_hash(model_hash)
    model_hash.key?('name') && super
  end
end

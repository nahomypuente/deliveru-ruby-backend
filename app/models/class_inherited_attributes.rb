# Module to handle class attributes that are not shared with subclasses
module ClassInheritedAttributes
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Module to define the class attributes getters and setters
  module ClassMethods
    def class_inherited_attributes(*args)
      @class_inherited_attributes ||= [:class_inherited_attributes]
      @class_inherited_attributes += args
      args.each do |arg|
        class_eval %(
          class << self; attr_accessor :#{arg} end
        )
      end
      @class_inherited_attributes
    end

    def inherited(subclass)
      @class_inherited_attributes.each do |class_inherited_attribute|
        instance_var_name = "@#{class_inherited_attribute}"
        instance_var = instance_variable_get(instance_var_name)
        if instance_var.class == Hash || instance_var.class == Array
          # Clone if it is a Hash or an Array
          instance_var = instance_var.clone
        end
        subclass.instance_variable_set(instance_var_name, instance_var)
      end
    end
  end
end

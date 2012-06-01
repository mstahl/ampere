# These are just utlity functions used by Ampere internally to generate Redis
# keys for various Ampere functions, for DRY excellence. 
module Ampere #:nodoc:
  module Keys #:nodoc:
    # These methods get mixed in to class and instance
    def self.included(base)
      # base.extend(ClassMethods)
      base.extend(self)
    end
    
    def key_for_has_many(parent_model, id, field)
      [parent_model, id, 'has_many', field].flatten.join('.')
    end
    
    def key_for_index(field)
      ['ampere', 'index', model_name.downcase, field].flatten.join('.')
    end
    
    private
    
    def model_name
      if self.class == Class
        to_s
      else
        self.class.to_s
      end
    end
  
  end
end
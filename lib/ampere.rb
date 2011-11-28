require "redis"

module Ampere
  class Model
    
    def initialize(hash = {})
      hash.each do |k, v|
        self.send("#{k}=", v)
      end
    end
    
    ### Class methods
    
    def self.field(name, type)
      define_method(name) do
        instance_variable_get "@#{name}"
      end
      
      define_method(:"#{name}=") do |val|
        instance_variable_set "@#{name}", val
      end
      
    end
    
  end
  
end
module Ampere
  class Model
    attr_reader :id
    
    # Models remember their fields
    @@fields = []
    
    ### Instance methods
    
    def initialize(hash = {})
      hash.each do |k, v|
        self.send("#{k}=", v)
      end
    end
    
    def save
      
    end
    
    def to_hash
      {}.tap do |hash|
        @@fields.each do |key|
          hash[key] = self.send(key)
        end
      end
    end
    
    ### Class methods
    
    def self.field(name, type)
      @@fields << name
      
      define_method(name) do
        instance_variable_get "@#{name}"
      end
      
      define_method(:"#{name}=") do |val|
        instance_variable_set "@#{name}", val
      end
      
    end
    
    def self.fields
      @@fields
    end
    
    ### Private methods
    
    
    
  end
  
end
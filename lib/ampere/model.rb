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
    
    def new?
      @id.nil? or not Ampere.connection.exists(@id)
    end
    
    def reload
      if self.new? then
        raise "Can't reload a new record"
      end
      
      @@fields.each do |k|
        self.send("#{k}=", Ampere.connection.hget(@id, k))
      end
      self
    end
    
    
    def save
      # Grab a fresh GUID from Redis by incrementing the "__guid" key
      if @id.nil? then
        @id = Ampere.connection["__guid"] || "0"
        Ampere.connection.incr("__guid")
      end
      
      Ampere.connection.hmset(@id, self.to_hash)
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
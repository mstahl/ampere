require 'pp'

module Ampere
  class Model
    attr_reader :id
    
    @fields = []
    
    ### Instance methods
    
    def initialize(hash = {})
      hash.each do |k, v|
        if k == 'id' then
          @id = v
        else
          self.send("#{k}=", v)
        end
      end
    end
    
    def new?
      @id.nil? or not Ampere.connection.exists(@id)
    end
    
    def reload
      if self.new? then
        raise "Can't reload a new record"
      end
      
      self.class.fields.each do |k|
        puts "Found #{k} in @@fields within #{self.class}"
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
      
      # Ampere.connection.hmset(@id, self.to_hash) # FIXME Somethin' wrong here. 
      self.to_hash.each do |k, v|
        Ampere.connection.hset(@id, k, v)
      end
    end
    
    def to_hash
      {:id => @id}.tap do |hash|
        self.class.fields.each do |key|
          hash[key] = self.send(key)
        end
      end
    end
    
    ### Various operators
    
    def ==(other)
      self.class.fields.each do |f|
        unless self.send(f) == other.send(f)
          return false
        end
      end
      
      return true
    end
    
    def !=(other)
      ! (self == other)
    end
    
    ### Class methods
    
    def self.create(hash = {})
      new(hash).save
    end
    
    def self.field(name, type)
      # class_variable_set('fields', class_variable_get('fields') + [name])
      @fields ||= []
      @fields << name
      
      define_method(name) do
        instance_variable_get "@#{name}"
      end
      
      define_method(:"#{name}=") do |val|
        instance_variable_set "@#{name}", val
      end
      
    end
    
    def self.fields
      @fields
    end
    
    def self.find(options = {})
      if options.class == String then
        new(Ampere.connection.hgetall(options))
      else
        # For each key in options
        # See if there's an index for this key
      end
    end
    
    def self.index(field_name, options = {})
    end
    
  end
  
end
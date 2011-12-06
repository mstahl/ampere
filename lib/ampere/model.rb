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
        self.send("#{k}=", Ampere.connection.hget(@id, k))
      end
      self
    end
    
    def save
      # Grab a fresh GUID from Redis by incrementing the "__guid" key
      if @id.nil? then
        @id = "#{self.class.to_s.downcase}.#{'%016x' % Ampere.connection.incr('__guid').hash}"
      end
      
      # Ampere.connection.hmset(@id, self.to_hash) # FIXME Somethin' wrong here. 
      self.to_hash.each do |k, v|
        Ampere.connection.hset(@id, k, v)
      end
      self
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
    
    def self.belongs_to(field_name, options = {})
    end
    
    def self.create(hash = {})
      new(hash).save
    end
    
    def self.delete(id)
      find(id).tap do |obj|
        Ampere.connection.del(obj.id)
      end
    end
    
    def self.field(name, options = {})
      @fields ||= []
      @fields << name
      
      class_eval do
        attr_accessor name.to_sym
      end
      
      define_method(name) do
        instance_variable_get "@#{name}"
      end
      
      define_method(:"#{name}=") do |val|
        instance_variable_set "@#{name}", val
      end
      
      self.send("#{name}=", options[:default]) if options.has_key?(:default)
    end
    
    def self.fields
      @fields
    end
    
    def self.find(options = {})
      if options.class == String then
        new(Ampere.connection.hgetall(options))
      else
        where(options)
      end
    end
    
    def self.has_one(field_name, options = {})
      klass_name = options[:class] || options['class'] || field_name
      klass = eval(klass_name.to_s.capitalize)
      
      class_eval do
        attr_accessor "#{field_name}_id".to_sym
      end
      
      define_method(field_name) do
        klass.find(self.send("#{field_name}_id"))
      end
      
      define_method(:"#{field_name}=") do |val|
        return nil if val.nil?
        
        unless val.class == klass
          raise "#{field_name} must be a #{klass_name}"
        end
        
        self.send("#{field_name}_id=", val.id)
      end
    end
    
    def self.has_many(field_name, options = {})
    end
    
    def self.index(field_name)
      raise "Can't index a nonexistent field!" unless @fields.include?(field_name)
      
      unless Ampere.connection.exists("__index.#{self.class.to_s.downcase}.#{field_name}")
        Ampere.connection.hset("__model", self.class.to_s.downcase)
      end
      @indices ||= []
      @indices << field_name
    end
    
    def self.where(options = {})
      # For each key in options
      # See if there's an index for this key
    end
    
  end
  
end
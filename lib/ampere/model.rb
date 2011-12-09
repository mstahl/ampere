require 'pp'

module Ampere
  class Model
    attr_reader :id
    
    @fields         = []
    @field_defaults = {}
    @indices        = []
    
    ### Instance methods
    
    def destroy
      self.class.delete(@id)
    end
    
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
        @id = "#{self.class.to_s.downcase}.#{Ampere.connection.incr('__guid')}"
      end
      
      self.to_hash.each do |k, v|
        Ampere.connection.hset(@id, k, v)
        
        # If there's an index on this field, also set a reference to this
        # model from there.
        if self.class.indices.include?(k) then
          # indexed_ids = (Ampere.connection.hget("ampere.index.#{self.class.to_s.downcase}.#{k}", v) or "").split(/:/)
          # indexed_ids |= [@id]
          Ampere.connection.hset(
            "ampere.index.#{self.class.to_s.downcase}.#{k}", 
            v, 
            ([@id] | (Ampere.connection.hget("ampere.index.#{self.class.to_s.downcase}.#{k}", v) or "").split(/:/)).join(":")
          )
        end
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
      Ampere.connection.del(id)
    end
    
    def self.field(name, options = {})
      @fields         ||= []
      @field_defaults ||= {}
      @indices        ||= []
      
      @fields << name
      
      attr_accessor :"#{name}"
      
      # Handle default value
      @field_defaults[name] = options[:default]
      
      define_method :"#{name}" do
        instance_variable_get("@#{name}") or self.class.field_defaults[name]
      end
    end
    
    def self.fields
      @fields
    end
    
    def self.field_defaults
      @field_defaults
    end
    
    def self.find(options = {})
      if options.class == String then
        if Ampere.connection.exists(options) then
          new(Ampere.connection.hgetall(options))
        else
          nil
        end
      else
        # TODO Write a handler for this case, even if it's an exception
      end
    end
    
    def self.has_one(field_name, options = {})
      klass_name = (options[:class] or options['class'] or field_name)
      
      class_eval do
        attr_accessor "#{field_name}_id".to_sym
      end
      
      define_method(field_name.to_sym) do
        eval(klass_name.to_s.capitalize).find(self.send("#{field_name}_id"))
      end
      
      define_method(:"#{field_name}=") do |val|
        return nil if val.nil?
        
        # unless val.class == klass
        #   raise "#{field_name} must be a '#{klass}' (is actually '#{val.class}')"
        # end
        
        self.send("#{field_name}_id=", val.id)
      end
    end
    
    def self.has_many(field_name, options = {})
      klass_name = (options[:class] or options['class'] or field_name)
      
      class_eval do
        attr_accessor "#{field_name}s".to_sym
      end
      
      define_method(field_name.to_sym) do
        
      end
      
      define_method(:"#{field_name}=") do |val|
        
      end
    end
    
    def self.index(field_name, options = {})
      raise "Can't index a nonexistent field!" unless @fields.include?(field_name)
      
      @fields         ||= []
      @field_defaults ||= {}
      @indices        ||= []
      
      @indices << field_name
    end
    
    def self.indices
      @indices
    end
    
    def self.where(options = {})
      results = []
      
      if options.empty? then
        results = Ampere.connection.keys("#{to_s.downcase}.*").map{|k| find(k)}
      else
        options.keys.each do |key|
          if @indices.include?(key) then
            result_ids = Ampere.connection.hget("ampere.index.#{to_s.downcase}.#{key}", options[key]) #.split(/:/)
        
            results |= result_ids.split(/:/).map {|id| find(id)}
          else
            raise "Cannot query on un-indexed fields."
          end
        end
      end
      results
    end
    
  end
  
end
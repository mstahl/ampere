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
    
    ### Class methods
    
    def self.all
      Ampere.connection.keys("#{to_s.downcase}.*").map{|m| find m}
    end
    
    def self.belongs_to(field_name, options = {})
      has_one field_name, options
    end
    
    def self.count
      Ampere.connection.keys("#{to_s.downcase}.*").length
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
      referred_klass_name = (options[:class] or options['class'] or field_name)
      my_klass_name = to_s.downcase
      
      field :"#{field_name}_id"
      
      define_method(field_name.to_sym) do
        return if self.send("#{field_name}_id").nil?
        eval(referred_klass_name.to_s.capitalize).find(self.send("#{field_name}_id"))
      end
      
      define_method(:"#{field_name}=") do |val|
        return nil if val.nil?
        # Set attr with key where referred model is stored
        self.send("#{field_name}_id=", val.id)
        # Also update that model's hash with a pointer back to here
        val.send("#{my_klass_name}_id=", self.send("id"))
      end
    end
    
    def self.has_many(field_name, options = {})
      klass_name = (options[:class] or options['class'] or field_name.to_s.gsub(/s$/, ''))
      my_klass_name = to_s.downcase
      
      define_method(:"#{field_name}") do
        (Ampere.connection.smembers("#{to_s.downcase}.#{self.id}.has_many.#{field_name}")).map do |id|
          eval(klass_name.to_s.capitalize).find(id)
        end
      end
      
      define_method(:"#{field_name}=") do |val|
        val.each do |v|
          Ampere.connection.sadd("#{to_s.downcase}.#{self.id}.has_many.#{field_name}", v.id)
          # Set pointer for belongs_to
          Ampere.connection.hset(v.id, "#{my_klass_name}_id", self.send("id"))
        end
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
      if options.empty? then
        []
      else
        indexed_fields    = options.keys & @indices
        nonindexed_fields = options.keys - @indices
        
        puts "query:"
        puts "    #{options}"
        puts "fields:"
        puts "    indexed:     #{indexed_fields}"
        puts "    non-indexed: #{nonindexed_fields}"

        results = []
        
        indexed_fields.each do |key|
          result_ids = Ampere.connection.hget("ampere.index.#{to_s.downcase}.#{key}", options[key]).split(/:/)

          results |= result_ids.map {|id| find(id)}
        end
        puts '!'
        p results
        results = all if results.nil? or results.empty?
        p results
        puts '!'
        nonindexed_fields.each do |key|
          results.select!{|r| r.send(key) == options[key]}
        end
        results
      end
    end
    
  end
  
end
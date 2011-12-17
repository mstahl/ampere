module Ampere
  class Model
    attr_reader :id
    
    @fields         = []
    @field_defaults = {}
    @indices        = []
    
    ### Instance methods
    
    # Compares this model with another one. If they are literally the same object
    # or have been stored and have the same ID, then they are equal.
    def ==(other)
      super or
        other.instance_of?(self.class) and
        not id.nil? and
        other.id == id
    end
    
    # Returns a Hash with all the fields and their values.
    def attributes
      {:id => @id}.tap do |hash|
        self.class.fields.each do |key|
          hash[key] = self.send(key)
        end
      end
    end
    
    # Deletes this instance out of the database.
    def destroy
      self.class.delete(@id)
    end
    
    # Delegates to ==().
    def eql?(other)
      self == other
    end
    
    # Calculates the hash of this object from the attributes hash instead of
    # using Object.hash.
    def hash
      attributes.hash
    end
    
    # Initialize an instance like this:
    # 
    #     Post.new :title => "Kitties: Are They Awesome?"
    def initialize(hash = {})
      hash.each do |k, v|
        if k == 'id' then
          @id = v
        else
          self.send("#{k}=", v)
        end
      end
    end
    
    # Returns true if this record has not yet been saved.
    def new?
      @id.nil? or not Ampere.connection.exists(@id)
    end
    
    # Reloads this record from the database.
    def reload
      if self.new? then
        raise "Can't reload a new record"
      end
      
      self.class.fields.each do |k|
        self.send("#{k}=", Ampere.connection.hget(@id, k))
      end
      self
    end
    
    # Saves this record to the database.
    def save
      # Grab a fresh GUID from Redis by incrementing the "__guid" key
      if @id.nil? then
        @id = "#{self.class.to_s.downcase}.#{Ampere.connection.incr('__guid')}"
      end
      
      self.attributes.each do |k, v|
        Ampere.connection.hset(@id, k, v)
      end
      
      self.class.indices.each do |index|
        if index.class == String or index.class == Symbol then
          Ampere.connection.hset(
            "ampere.index.#{self.class.to_s.downcase}.#{index}", 
            instance_variable_get("@#{index}"), 
            ([@id] | (Ampere.connection.hget("ampere.index.#{self.class.to_s.downcase}.#{index}", instance_variable_get("@#{index}")) or "")
            .split(/:/)).join(":")
          )
        elsif index.class == Array then
          key = index.map{|i| instance_variable_get("@#{i}")}.join(':')
          val = ([@id] | (Ampere.connection.hget("ampere.index.#{self.class.to_s.downcase}.#{index}", key) or "")
                .split(/:/)).join(":")
          Ampere.connection.hset(
            "ampere.index.#{self.class.to_s.downcase}.#{index.join(':')}",
            key,
            val
          )
        end
      end
      self
    end
    
    def update_attribute(key, value)
      raise "Cannot update a nonexistent field!" unless self.class.fields.include?(key)
      self.send("#{key}=", value)
      Ampere.connection.hset(@id, key, value)
    end
    
    def update_attributes(hash = {})
      # The efficient way, that I haven't figured out how to do yet:
      # Ampere.connection.hmset(@id, hash)
      
      # The inefficient way I know how to do right now:
      hash.each do |k, v|
        update_attribute(k, v)
      end
    end
    
    ### Class methods
    
    # Returns an array of all the records that have been stored.
    def self.all
      Ampere.connection.keys("#{to_s.downcase}.*").map{|m| find m}
    end
    
    # Declares a belongs_to relationship to another model.
    def self.belongs_to(field_name, options = {})
      has_one field_name, options
    end
    
    # Like @indices, but only returns the compound indices this class defines.
    def self.compound_indices
      @indices.select{|i| i.class == Array}
    end
    
    # Returns the number of instances of this record that have been stored.
    def self.count
      Ampere.connection.keys("#{to_s.downcase}.*").length
    end
    
    # Instantiates and saves a new record.
    def self.create(hash = {})
      new(hash).save
    end
    
    # Deletes the record with the given ID.
    def self.delete(id)
      Ampere.connection.del(id)
    end
    
    # Declares a field. See the README for more details.
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
    
    # Finds the record with the given ID, or the first that matches the given conditions
    def self.find(options = {})
      if options.class == String then
        if Ampere.connection.exists(options) then
          new(Ampere.connection.hgetall(options))
        else
          nil
        end
      else
        # TODO Write a handler for this case, even if it's an exception
        raise "Cannot find by #{options.class} yet"
      end
    end
    
    # Defines a has_one relationship with another model. See the README for more details.
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
    
    # Defines a has_many relationship with another model. See the README for more details.
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
    
    # Defines an index. See the README for more details.
    def self.index(field_name, options = {})
      @fields         ||= []
      @field_defaults ||= {}
      @indices        ||= []
      if field_name.class == String or field_name.class == Symbol then
        raise "Can't index a nonexistent field!" unless @fields.include?(field_name)
      elsif field_name.class == Array then
        field_name.each{|f| raise "Can't index a nonexistent field!" unless @fields.include?(f)}
        field_name.sort!
      else
        raise "Can't index a #{field_name.class}"
      end
      
      @indices << field_name
    end
    
    def self.indices
      @indices
    end
    
    # Finds an array of records which match the given conditions. This method is
    # much faster when all the fields given are indexed.
    def self.where(options = {})
      if options.empty? then
        Ampere::Collection.new(eval(to_s), [])
      else
        indexed_fields    = (options.keys & @indices) + compound_indices_for(options)
        nonindexed_fields = (options.keys - @indices) - compound_indices_for(options).flatten
        
        results = nil
        
        unless indexed_fields.empty?
          indexed_fields.map {|key|
            if key.class == String or key.class == Symbol then
              Ampere.connection.hget("ampere.index.#{to_s.downcase}.#{key}", options[key]).split(/:/) #.map {|id| find(id)}
            else
              # Compound index
              Ampere.connection.hget(
                "ampere.index.#{to_s.downcase}.#{key.join(':')}", 
                key.map{|k| options[k]}.join(':')
              ).split(/:/) #.map {|id| find(id)}
            end
          }.each {|s|
            return s if s.empty?
          
            if results.nil? then
              results = s
            else
              results &= s
            end
          }
        end
          
        unless nonindexed_fields.empty?
          results = all if results.nil?
          results.map!{|r| r.class == String ? find(r) : r}
          nonindexed_fields.each do |key|
            results.select!{|r| r.send(key) == options[key]}
          end
        end
        
        # TODO The eval(to_s) trick seems a little... ghetto. 
        Ampere::Collection.new(eval(to_s), results.reverse)
      end
    end
    
    private
    
    def self.compound_indices_for(query)
      compound_indices.select{|ci|
        (query.keys - ci).empty?
      }
    end
    
    
  end
  
end

module Ampere
  # Including the `Ampere::Model` module into one of your classes mixes in all 
  # the class and instance methods of an Ampere model. See individual methods
  # for more information.
  module Model
    def self.included(base)
      base.extend(ClassMethods)
      
      base.extend(Keys)
      
      base.class_eval do
        include(::ActiveModel::Validations)
        include(Rails.application.routes.url_helpers) if defined?(Rails)
        include(ActionController::UrlFor) if defined?(Rails)

        include(Ampere::Keys)
        
        attr_reader :id
      
        attr_accessor :fields
        attr_accessor :field_defaults
        attr_accessor :indices
        attr_accessor :field_types
    
        @fields         = []
        @field_defaults = {}
        @indices        = []
        @field_types    = {}
      end
    end
    
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
    def initialize(hash = {}, unmarshal = false)
      hash.each do |k, v|
        if k == 'id' then
          @id = unmarshal ? Marshal.load(v) : v
        else
          self.send("#{k}=", (unmarshal and not k =~ /_id$/) ? Marshal.load(v) : v)
        end
      end
    end
    
    # Returns true if this record has not yet been saved.
    def new?
      @id.nil? or not Ampere.connection.exists(@id)
    end
    alias :new_record? :new?
    
    def persisted?
      not @id.nil?
    end
    
    # Reloads this record from the database.
    def reload
      if self.new? then
        raise "Can't reload a new record"
      end
      
      self.class.fields.each do |k|
        v = Ampere.connection.hget(@id, k)
        if k =~ /_id$/ then
          self.send("#{k}=", v)
        else
          self.send("#{k}=", Marshal.load(v))
        end
      end
      self
    end
    
    def route_key #:nodoc:
      raise "route_key was called"
      @id
    end
    
    # Saves this record to the database.
    def save
      self.class.unique_indices.each do |idx|
        # For each uniquely-indexed field, look up the index for that field,
        # and throw an exception if this record's value for that field is in
        # the index already.
        if Ampere.connection.hexists(key_for_index(idx), instance_variable_get("@#{idx}")) then
          raise "Cannot save non-unique value for #{idx}"
        end
      end
      
      # Grab a fresh GUID from Redis by incrementing the "__guid" key
      if @id.nil? then
        @id = "#{self.class.to_s.downcase}.#{Ampere.connection.incr('__guid')}"
      end
      
      self.attributes.each do |k, v|
        Ampere.connection.hset(@id, k, k =~ /_id$/ ? v : Marshal.dump(v))
      end
      
      self.class.indices.each do |index|
        if index.class == String or index.class == Symbol then
          Ampere.connection.hset(
            key_for_index(index), 
            instance_variable_get("@#{index}"), 
            ([@id] | (Ampere.connection.hget(key_for_index(index), instance_variable_get("@#{index}")) or "")
            .split(/:/)).join(":")
          )
        elsif index.class == Array then
          key = index.map{|i| instance_variable_get("@#{i}")}.join(':')
          val = ([@id] | (Ampere.connection.hget(key_for_index(index), key) or "")
                .split(/:/)).join(":")
          Ampere.connection.hset(
            key_for_index(index.join(':')),
            key,
            val
          )
        end
      end
      self
    end
    
    def to_key #:nodoc:
      @id.nil? ? nil : @id
    end
    
    def to_param
      to_key
    end
    
    def update_attribute(key, value)
      raise "Cannot update a nonexistent field!" unless self.class.fields.include?(key)
      self.send("#{key}=", value)
      Ampere.connection.hset(@id, key, Marshal.dump(value))
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
    module ClassMethods #:nodoc:
      # Returns a lazy collection of all the records that have been stored.
      def all
        Ampere::Collection.new(self, Ampere.connection.keys("#{to_s.downcase}.*"))
      end
    
      # Declares a belongs_to relationship to another model.
      def belongs_to(field_name, options = {})
        has_one field_name, options
      end
    
      # Like @indices, but only returns the compound indices this class defines.
      def compound_indices
        @indices.select{|i| i.class == Array}
      end
    
      # Returns the number of instances of this record that have been stored.
      def count
        Ampere.connection.keys("#{to_s.downcase}.*").length
      end
    
      # Instantiates and saves a new record.
      def create(hash = {})
        new(hash).save
      end
      alias :create! :create
    
      # Deletes the record with the given ID.
      def delete(id)
        Ampere.connection.del(id)
      end
    
      # Declares a field. See the README for more details.
      def field(name, options = {})
        @fields         ||= []
        @field_defaults ||= {}
        @indices        ||= []
        @unique_indices ||= []
        @field_types    ||= {}
      
        @fields << name
      
        # attr_accessor :"#{name}"
      
        # Handle default value
        @field_defaults[name] = options[:default]
      
        # Handle type, if any
        if options[:type] then
          @field_types[:"#{name}"] = options[:type].to_s
        end
      
        define_method :"#{name}" do
          instance_variable_get("@#{name}") or self.class.field_defaults[name]
        end
      
        define_method :"#{name}=" do |val|
          if not self.class.field_types[:"#{name}"] or val.is_a?(eval(self.class.field_types[:"#{name}"])) then
            instance_variable_set("@#{name}", val)
          else
            raise "Cannot set field of type #{self.class.field_types[name.to_sym]} with #{val.class} value"
          end
        end
      end
    
      def fields
        @fields
      end
    
      def field_defaults
        @field_defaults
      end
    
      def field_types
        @field_types
      end
    
      # Finds the record with the given ID, or the first that matches the given conditions
      def find(options = {})
        if options.class == String then
          if Ampere.connection.exists(options) then
            new(Ampere.connection.hgetall(options), true)
          else
            nil
          end
        else
          # TODO Write a handler for this case, even if it's an exception
          raise "Cannot find by #{options.class} yet"
        end
      end
    
      # Defines a has_one relationship with another model. See the README for more details.
      def has_one(field_name, options = {})
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
      def has_many(field_name, options = {})
        klass_name = (options[:class] or options['class'] or field_name.to_s.gsub(/s$/, ''))
        my_klass_name = to_s.downcase
      
        define_method(:"#{field_name}") do
          (Ampere.connection.smembers(key_for_has_many(to_s.downcase, self.id, field_name))).map do |id|
            eval(klass_name.to_s.capitalize).find(id)
          end
        end
      
        define_method(:"#{field_name}=") do |val|
          val.each do |v|
            Ampere.connection.sadd(key_for_has_many(to_s.downcase, self.id, field_name), v.id)
            # Set pointer for belongs_to
            Ampere.connection.hset(v.id, "#{my_klass_name}_id", self.send("id"))
          end
        end
      end
    
      # Defines an index. See the README for more details.
      def index(field_name, options = {})
        # TODO There has just got to be a better way to handle this.
        @fields         ||= []
        @field_defaults ||= {}
        @indices        ||= []
        @unique_indices ||= []
        @field_types    ||= {}
      
        if field_name.class == String or field_name.class == Symbol then
          # Singular index
          raise "Can't index a nonexistent field!" unless @fields.include?(field_name)
        elsif field_name.class == Array then
          # Compound index
          field_name.each{|f| raise "Can't index a nonexistent field!" unless @fields.include?(f)}
          field_name.sort!
        else
          raise "Can't index a #{field_name.class}"
        end
      
        @indices << field_name
        @unique_indices << field_name if options[:unique]
      end
    
      def indices
        @indices
      end
      
      def unique_indices
        @unique_indices
      end
    
      # Finds an array of records which match the given conditions. This method is
      # much faster when all the fields given are indexed.
      def where(options = {})
        if options.empty? then
          Ampere::Collection.new(eval(to_s), [])
        else
          indexed_fields    = (options.keys & @indices) + compound_indices_for(options)
          nonindexed_fields = (options.keys - @indices) - compound_indices_for(options).flatten
        
          results = nil
        
          unless indexed_fields.empty?
            indexed_fields.map {|key|
              if key.class == String or key.class == Symbol then
                Ampere.connection.hget(key_for_index(key), options[key]).split(/:/) #.map {|id| find(id)}
              else
                # Compound index
                Ampere.connection.hget(
                  key_for_index(key.join(':')),
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
            results = results.to_a.map{|r| r.class == String ? find(r) : r}
            nonindexed_fields.each do |key|
              results.select!{|r| 
                r.send(key) == options[key]
              }
            end
          end
        
          # TODO The eval(to_s) trick seems a little... ghetto. 
          Ampere::Collection.new(eval(to_s), results.reverse)
        end
      end
    
      private
    
      def compound_indices_for(query) #:nodoc:
        compound_indices.select{|ci|
          (query.keys - ci).empty?
        }
      end
      
    end
    
  end
  
end

# require 'pp'

module Ampere
  # Collections are search results from queries. They can be used like arrays,
  # but you cannot add anything to them. 
  class Collection
    attr_reader :raw_array
    attr_reader :model
    
    # Instance methods ########################################################
    
    def initialize(model_class, array = [])
      @raw_array = array
      @model = model_class
    end
    
    # Index into the search results. Lazily loads models when they're accessed.
    def [](idx)
      if @raw_array[idx].is_a?(Ampere::Model) then
        @raw_array[idx]
      else
        # This is still an ID. Find it.
        @raw_array[idx] = @model.find(@raw_array[idx])
      end
    end
    
    # Delegates to internal array.
    def count
      @raw_array.count
    end
    
    # Delegates to internal array.
    def empty?
      @raw_array.empty?
    end
    
    # Returns first item or first n elements.
    def first(n = 0)
      if n == 0 then
        self[0]
      else
        (0..(n - 1)).map{|i| self[i]}
      end
    end
    
    # Returns the last item.
    def last
      self[-1]
    end
    
    # Delegates to internal array.
    def length
      @raw_array.count
    end
    
    # Finds all the un-found items and returns an applicatively-evaluated array.
    def to_a
      @raw_array.map do |m|
        if m.is_a?(Ampere::Model) then
          m
        else
          @model.find(m)
        end
      end
    end
    
    # Class methods ###########################################################
    
    
  end
end

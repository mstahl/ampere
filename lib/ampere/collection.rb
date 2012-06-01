# require 'pp'

module Ampere
  # Collections are search results from queries. They can be used like arrays,
  # but you cannot add anything to them. 
  class Collection
    include Enumerable
    
    attr_reader :raw_array
    attr_reader :model
    
    # Instance methods ########################################################
    
    def initialize(model_class, array = [])
      @raw_array = array
      @model = model_class
    end
    
    def each
      @raw_array.each_with_index do |x, i|
        if x.is_a?(Ampere::Model) then
          yield(x)
        else
          raw_array[i] = @model.find(x)
          yield(raw_array[i])
        end
      end
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
    def empty?
      @raw_array.empty?
    end

    # Returns the last item.
    def last
      self[-1]
    end
    
    # Class methods ###########################################################
    
    
  end
end

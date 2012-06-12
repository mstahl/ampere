module Ampere
  module Timestamps
    def self.included(base)
      base.class_eval do
        field :created_at
        field :updated_at
        
        define_model_callbacks :create, :update, :save
        
        before_create do
          @updated_at = Time.now
          if @created_at.nil? then
            @created_at = Time.now
          end
        end
      
        before_save do
          @updated_at = Time.now
        end
      end
    end
  end
end

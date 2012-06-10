module Ampere
  module Timestamps
    def self.included(base)
      base.class_eval do
        before_create do
          @created_at = Time.now
        end
      
        before_save do
          @updated_at = Time.now
        end
      end
    end
  end
end

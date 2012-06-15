module Ampere #:nodoc:
  module Generators #:nodoc:
    class ModelGenerator < Rails::Generators::NamedBase #:nodoc:
      source_root File.expand_path("../templates", __FILE__)

      desc "Creates an Ampere model"
      argument :attributes, :type => :array, :default => [], :banner => "field field"

      check_class_collision

      def create_model_file
        template "model.rb.tt", File.join("app/models", class_path, "#{file_name}.rb")
      end

      hook_for :test_framework
    
      unless methods.include?(:module_namespacing)

        # This is only defined on Rails edge at the moment, so include here now
        # as per: https://github.com/mongoid/mongoid/issues/744
        def module_namespacing(&block)
          yield if block
        end
      end
    end
  end
end

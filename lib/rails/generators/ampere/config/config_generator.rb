module Ampere
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)
    
      desc "Installs a skeleton Ampere config file for you."
    
      argument :prefix, :type => :string, :optional => true
    
      def create_config_file
        template 'ampere.yml', File.join('config', "ampere.yml")
      end
    end
  end
end

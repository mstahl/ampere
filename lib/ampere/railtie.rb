require 'rails'

module Ampere
  class Railtie < Rails::Railtie
    if config.respond_to?(:app_generators) then
      config.app_generators.orm :ampere, :migration => false
    else
      config.generators.orm :ampere, :migration => false
    end
    
    console do
      Ampere.connect
      puts "[ampere] Connected."
    end
    
    initializer 'railtie.initialize_redis_connection' do |app|
      config_file = Rails.root.join("config", "ampere.yml")
      
      options = {
        'development' => {
          'host' => '127.0.0.1',
          'port' => 6379
        },
        'test' => {
          'host' => '127.0.0.1',
          'port' => 6379
        },
        'production' => {
          'host' => '127.0.0.1',
          'port' => 6379
        },
      }
      
      if config_file.file?
        options = YAML.load_file(config_file)
      end
      
      Rails.logger.info "[ampere] Initializing redis connection redis://#{options[Rails.env]['host']}:#{options[Rails.env]['port']}"
    end
    
    rake_tasks do
      load File.join(__FILE__, '..', 'rails', 'tasks', 'ampere.rake')
    end
    
  end
  
end
require "redis"

module Ampere
  @@connection = nil
  
  def self.connect(options = {})
    @@connection = Redis.connect(options)
  end
  
  def self.disconnect
    @@connection.quit
    @@connection = nil
  end
  
  def self.connected?
    !! @@connection
  end
  
end

Dir[File.join(File.dirname(__FILE__), 'ampere', '**', '*.rb')].each {|f| require f}
require "redis"

module Ampere
  @@connection = nil
  
  def self.connect(options = {})
    @@connection = Redis.connect(options)
  end
  
  def self.disconnect
    return unless connected?
    @@connection.quit
    @@connection = nil
  end
  
  def self.connected?
    !! @@connection
  end
  
  def self.connection
    @@connection
  end
end

Dir[File.join(File.dirname(__FILE__), 'ampere', '**', '*.rb')].each {|f| require f}
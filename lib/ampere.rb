require "active_record"
require "redis"

# The Ampere module contains methods to connect/disconnect and gives access to
# the Redis connection directly (though you really shouldn't need to use it).
module Ampere
  @@connection = nil
  
  # Open a new Redis connection. `options` is passed directly to the Redis.connect
  # method.
  def self.connect(options = {})
    @@connection = Redis.connect(options)
  end
  
  # Closes the Redis connection.
  def self.disconnect
    return unless connected?
    @@connection.quit
    @@connection = nil
  end
  
  # Returns `true` if the Redis connection is active.
  def self.connected?
    !! @@connection
  end
  
  # Gives access to the Redis connection object.
  def self.connection
    @@connection
  end

  # Alias for Ampere.redis.flushall
  def self.flush
    @@connection.flushall if connected?
  end
  
end

Dir[File.join(File.dirname(__FILE__), 'ampere', '**', '*.rb')].each {|f| require f}

require File.join(File.dirname(__FILE__), "rails", "railtie.rb") if defined?(Rails)


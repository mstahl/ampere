require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/features/'
end

require 'rspec'
require 'rspec/autorun'
require 'shoulda'

require 'ampere'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "spec", "support", "**", "*.rb")].each {|f| puts "REQUIRING: #{f}"; require f}


# Not used yet
RSpec.configure do |config|
  config.mock_with :rspec
end

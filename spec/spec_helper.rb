require 'rspec'
require 'rspec/autorun'
require 'shoulda'

require 'ampere'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "spec", "support", "**", "*.rb")].each {|f| puts "REQUIRING: #{f}"; require f}


# Not used yet
RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec
end

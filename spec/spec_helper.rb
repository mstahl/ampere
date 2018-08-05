require 'rspec'

require 'byebug'
require 'shoulda'
require 'timecop'

require 'ampere'

Dir[File.join(File.dirname(__FILE__), "spec", "support", "**", "*.rb")].each {|f| puts "REQUIRING: #{f}"; require f}

RSpec.configure do |config|
  config.mock_with :rspec
end

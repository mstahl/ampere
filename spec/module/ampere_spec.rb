require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe 'Ampere', :ampere => true do
  before :all do
    Ampere.connect
    Redis.new.flushall
  end
  
  it 'should be able to connect' do
    Ampere.should be_connected
  end
  
  it 'should be able to flush', wip:true do
    value = "%016x" % rand(2 ** 64)
    Ampere.should be_connected
    Ampere.connection.setex("ampere.test.flush_test", 60, value)
    Ampere.flush
    Ampere.connection.get("ampere.test.flush_test").should_not eq(value)
  end
  
  it 'should be able to disconnect' do
    # NOTE: This test must always be run last
    Ampere.disconnect
    Ampere.should_not be_connected
  end
  
  after :all do
    Redis.new.flushall
    Ampere.disconnect
  end
end


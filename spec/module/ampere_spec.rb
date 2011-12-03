require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe 'Ampere', :ampere => true do
  before :all do
    Ampere.connect
    Redis.new.flushall
  end
  
  it 'should be able to connect' do
    Ampere.connected?.should be_true
    Ampere.disconnect
    Ampere.connected?.should be_false
  end
  
  # context 'Redis data store', :redis => true do
  #   it 'should come with a __guid set' do
  #     Redis.new['guid'].should == 0
  #   end
  # end
  
  after :all do
    Redis.new.flushall
    Ampere.disconnect
  end
end


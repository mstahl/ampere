require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe 'Ampere' do
  it 'should be able to connect' do
    Ampere.connected?.should be_false
    Ampere.connect
    Ampere.connected?.should be_true
    Ampere.disconnect
    Ampere.connected?.should be_false
  end
end
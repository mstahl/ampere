require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe 'queries', :queries => true do
  before :each do
    Redis.new.flushall
    Ampere.connect
    
    class Motorcycle < Ampere::Model
      field :make
      field :model
      field :year
    end
    
    @bike = Motorcycle.create make: "Honda", model: "CB400", year: "1990"
  end
  
  ###
  
  it 'should openly refuse to set one field that does not exist' do
    (->{@bike.update_attribute :this_field_does_not_exist, "This is never gonna get stored."}).should raise_error
  end
  
  it 'should be able to update one field atomically' do
    @bike.model.should == "CB400"
    @bike.update_attribute :model, "CB450SC"
    @bike.model.should == "CB450SC"
    @bike.reload.model.should == "CB450SC"
    
    @bike.year.should == "1990"
    @bike.update_attribute :year, "1986"
    @bike.year.should == "1986"
    @bike.reload
    @bike.year.should == "1986"
  end
  
  it 'should be able to update multiple fields atomically' do
    @bike.update_attributes model: "CB750",
                             year:  "1996"
    @bike.model.should == "CB750"
    @bike.year.should == "1996"
    @bike.reload.model.should == "CB750"
    @bike.reload.year.should == "1996"
  end
  
  ###
  
  after :all do
    Redis.new.flushall
    Ampere.connect
  end
end

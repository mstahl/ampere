require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe 'queries', :queries => true do
  before :each do
    Redis.new.flushall
    Ampere.connect
  
    class Motorcycle
      include Ampere::Model
    
      field :make
      field :model
      field :year
    end
  
    @bike = Motorcycle.create make: "Honda", model: "CB400", year: "1990"
  end

  ###

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

  it 'should openly refuse to set fields that do not exist' do
    (->{
      @bike.update_attribute :this_field_does_not_exist, "Lorem ipsum dolor sit amet."
    }).should raise_error
    (->{
      # TODO Once this operation is made atomic, this test needs to be updated to also
      # include keys that do exist, in various orders. Even if real fields are included,
      # no fields should be updated if any part of this query would fail. To emulate this
      # behaviour in the meantime, possibly check all keys of attributes hash to see if 
      # they exist before performing the queries or synchronize during.
      @bike.update_attributes this_field_does_not_exist: "Ut enim ad minim veniam.",
                              neither_does_this_one:     "Duis aute irure dolor in."
    }).should raise_error
  end

  ###

  after :all do
    Redis.new.flushall
    Ampere.connect
  end
end

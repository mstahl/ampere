require File.join(File.dirname(__FILE__), "..", "..", "spec_helper.rb")

describe 'belongs_to relationships', :belongs_to => true do
  before :all do
    Redis.new.flushall
    Ampere.connect
    
    # These are used by the has_one/belongs_to example below
    class Car < Ampere::Model
      field :make
      field :model
      field :year

      has_one :engine
      has_many :passengers
    end

    class Engine < Ampere::Model
      field :displacement
      field :cylinders
      field :configuration
      
      belongs_to :car
    end
    
    class Passenger < Ampere::Model
      field :name
      field :seat
      
      belongs_to :car
    end
    
    @car    = Car.create :make  => "Lamborghini",
                         :model => "Countach",
                         :year  => "1974"
    @engine = Engine.create :displacement  => "5167",
                            :cylinders     => "12",
                            :configuration => "V"
    @driver = Passenger.create :name => "Max",
                               :seat => "driver"
    @passenger = Passenger.create :name => "Leila",
                                  :seat => "passenger"
  end
  
  ###
  
  it 'sets accessor methods for a belongs_to relationship' do
    # Other side of a has_many
    @driver.should respond_to(:car)
    # Other side of a has_one
    @engine.should respond_to(:car)
  end
  
  it 'sets belongs_to pointer for has_one relationship that is set from the parent' do
    @car.engine = @engine
    @car.save
    @engine.save
    
    car    = Car.find(@car.id)
    engine = Engine.find(@engine.id)
    
    car.engine.should == @engine
    engine.car.should == @car
    
    # Cleanup
    @car.engine = nil
    @engine.car = nil
    @car.save
    @engine.save
  end
  
  it 'sets belongs_to pointer for has_one relationship that is set from the child' do
    @engine.car = @car
    @car.save
    @engine.save
    
    car    = Car.find(@car.id)
    engine = Engine.find(@engine.id)
    
    car.engine.should == @engine
    engine.car.should == @car
    
    # Cleanup
    @car.engine = nil
    @engine.car = nil
    @car.save
    @engine.save
  end
  
  it 'sets belongs_to pointer for has_many relationship' do
    pending
  end
  
  ###
  
  after :all do
    Redis.new.flushall
    Ampere.connect
  end
end

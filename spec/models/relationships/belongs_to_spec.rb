require File.join(File.dirname(__FILE__), "..", "..", "spec_helper.rb")

describe 'belongs_to relationships', :belongs_to => true do
  
  class Car
    include Ampere::Model

    field :make
    field :model
    field :year

    has_one :engine
    has_many :passengers
  end

  class Engine
    include Ampere::Model

    field :displacement
    field :cylinders
    field :configuration

    belongs_to :car
  end

  class Passenger
    include Ampere::Model

    field :name
    field :seat

    belongs_to :car
  end
  
  before :all do
    Redis.new.flushall
    Ampere.connect
    
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
    @car.passengers = @car.passengers + [@driver]
    @car.passengers = @car.passengers + [@passenger]
    @car.save
  
    @driver.reload
    @passenger.reload
  
    @driver.car.should == @car
    @passenger.car.should == @car
  end

  ###

  after :all do
    Redis.new.flushall
    Ampere.connect
  end
end

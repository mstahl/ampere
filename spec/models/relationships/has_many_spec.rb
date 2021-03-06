require File.join(File.dirname(__FILE__), "..", "..", "spec_helper.rb")

describe 'has_many relationships', :has_many => true do

  class Car
    include Ampere::Model
  
    field :make
    field :model
    field :year

    has_many :passengers
  end

  class Passenger
    include Ampere::Model
  
    field :name
    field :seat
  
    belongs_to :car
  end

  before :each do
    Redis.new.flushall
    Ampere.connect
  
    @car    = Car.create :make  => "Lamborghini",
                         :model => "Countach",
                         :year  => "1974"
    @driver = Passenger.create :name => "Max",
                               :seat => "driver"
    @passenger = Passenger.create :name => "Leila",
                                  :seat => "passenger"

  end

  ###

  it 'should define the necessary methods for has_many relationships' do
    # Attr accessors
    @car.should respond_to(:passengers)
    @car.should respond_to(:"passengers=")
  end

  it 'should be able to add items to has_many relationships' do
    @car.passengers = @car.passengers + [@driver]
    @car.passengers = @car.passengers + [@passenger]

    @car.save
    @car.reload
  
    @driver.reload
    @passenger.reload

    @car.passengers.should include(@driver)
    @car.passengers.should include(@passenger)
  end
  
  it 'should add a set of IDs to Redis', wip:true do
    @car.passengers = @car.passengers + [@driver]
    Ampere.connection.keys.should include("car.#{@car.id}.has_many.passengers")
  end

  # it 'should be able to remove items from has_many relationships' do
  #   pending
  # end

  # it 'should be able to query has_many relationships' do
  #   pending
  # end

  ###

  after :all do
    Ampere.disconnect
    Redis.new.flushall
  end

end

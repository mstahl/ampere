require File.join(File.dirname(__FILE__), "..", "..", "spec_helper.rb")

describe 'belongs_to relationships' do
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
  end
  
  ###
  
  it 'sets accessor methods for a belongs_to relationship' do
  end
  
  it 'sets belongs_to pointer for has_one relationship' do
  end
  
  it 'sets belongs_to pointer for has_many relationship' do
  end
  
  ###
  
  after :all do
    Redis.new.flushall
    Ampere.connect
  end
end

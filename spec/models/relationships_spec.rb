require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe "Model relationships", :mode => true, :relationships => true do
  before :all do
    Redis.new.flushall
    Ampere.connect
  end
  
  ###
  
  context 'has_one relationships' do
    before :all do
      # These are used by the has_one/belongs_to example below
      class Car < Ampere::Model
        field :make
        field :model
        field :year

        has_one :engine
      end

      class Engine < Ampere::Model
        field :displacement
        field :cylinders
        field :configuration
        
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
    
    it 'can store a relationship to one model instance from another using an attr_accessor' do
      @car.engine_id = @engine.id
      @car.save
      @car.reload
      @car.engine_id.should == @engine.id
      @car.engine.should == @engine
      
      @car.engine_id = nil
      @car.save
      @car.engine.should be_nil
    end
    
    it 'can store a relationship to one model instance from another using custom accessor methods' do
      
    end
  end
  
  context 'belongs_to relationships' do
    it 'should associate a belongs_to when a has_many is set' do
    end
    
    it 'should associate a belongs_to when a has_one is set' do
      
    end
  end
  
  context 'has_many relationships' do
  end
  
  ###
  
  after :all do
    Redis.new.flushall
  end
end


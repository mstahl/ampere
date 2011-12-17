require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe 'Collections', :collections => true do
  before :all do
    Redis.new.flushall
    Ampere.connect
    
    class President < Ampere::Model
      field :name
      field :party
      
      index :party
    end

    President.create :name  => "Millard Fillmore"      , :party => "Whig"
    President.create :name  => "Ulysses S. Grant"      , :party => "Republican"
    President.create :name  => "Abraham Lincoln"       , :party => "Republican"
    President.create :name  => "Franklin D. Roosevelt" , :party => "Democratic"
    President.create :name  => "John F. Kennedy"       , :party => "Democratic"
    President.create :name  => "Jimmy Carter"          , :party => "Democratic"
  end
  
  ###
  
  it 'should be returned by where() queries' do
    democrats = President.where(:party => "Democratic")
    democrats.class.should == Ampere::Collection
    democrats.model.should == President
    democrats.raw_array.length.should == 3
  end
  
  it 'should be accessible via [] like an Array' do
    whigs = President.where(:party => "Whig")
    whigs[0].name.should == "Millard Fillmore"
  end
  
  it 'should lazily load model instances searched for with indexed fields' do
    whigs = President.where(:party => "Whig")
    whigs.raw_array.first.class.should == String
    whigs[0].name.should == "Millard Fillmore"
    whigs.raw_array.first.class.should == President
  end
  
  it 'should return its first() item' do
    republicans = President.where(:party => "Republican")
    republicans.first.name.should == "Ulysses S. Grant"
  end
  
  it 'should return its first(n) items' do
    republicans = President.where(:party => "Republican")
    republicans.first(2).map(&:name).should == ["Ulysses S. Grant", "Abraham Lincoln"]
  end
  
  it 'should return its last() item' do
    democrats = President.where(:party => "Democratic")
    democrats.last.name.should == "Jimmy Carter"
  end
  
  it 'should be convertible to an array' do
    republicans = President.where(:party => "Republican")
    republicans.to_a.map(&:name).should == ["Ulysses S. Grant", "Abraham Lincoln"]
  end
  
  ###
  
  after :all do
    Ampere.disconnect
    Redis.new.flushall
  end
end


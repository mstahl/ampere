require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe 'Collections are Ennumerable', :collections => true, :ennumerable => true do
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
  
  it 'should implement the #each method correctly' do
    presidents = []
    President.all.each {|p| presidents << p.name}
    presidents.should == [
      "Millard Fillmore"     ,
      "Ulysses S. Grant"     ,
      "Abraham Lincoln"      ,
      "Franklin D. Roosevelt",
      "John F. Kennedy"      ,
      "Jimmy Carter"         
    ]
  end
  
  # These are just a handful of methods to ensure that the Enumerable module is
  # being included correctly. They can safely be factored out since the #each 
  # one above should cover Enumerable if it's being included correctly.
  it 'should implement the #all? method correctly' do
    President.all.all? {|p| p.party != 'Green'}.should be_true
    President.all.all? {|p| p.party == 'Democratic'}.should be_false
  end

  it 'should implement the #any? method correctly' do
    President.all.any? {|p| p.party == 'Whig'}.should be_true
    President.all.any? {|p| p.party == 'Green'}.should be_false
  end
  
  it 'should implement the #map method correctly' do
    President.all.map(&:party).should == %w{Whig Republican Republican Democratic Democratic Democratic}
  end

  it 'should implement the #inject method correctly' do
    party_counts = President.all.inject({}) do |h, p|
      h[p.party.downcase.to_sym] ||= 0
      h[p.party.downcase.to_sym] += 1
      h
    end
    party_counts.should == {
      whig: 1,
      republican: 2,
      democratic: 3
    }
  end

  
end


require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe 'queries', :queries => true do
  before :each do
    Redis.new.flushall
    Ampere.connect
  
    class Kitty
      include Ampere::Model
    
      field :name
      field :breed
      field :age
      field :color
    
      index :name     # => Unique
      index :color    # => Non-unique
    end
  
    @kitty_paws = Kitty.create name:  'Kitty Paws',
                               breed: 'Domestic shorthair',
                               age:   19,
                               color: 'orange'
    @nate       = Kitty.create name:  'Nate',
                               breed: 'Domestic shorthair',
                               age:   17,
                               color: 'black'
    @jinxii     = Kitty.create name:  'Jinxii',
                               breed: 'Chartreux',
                               age:   3,
                               color: 'grey'
    @italics    = Kitty.create name:  'Italics',
                               breed: 'Siberian',
                               age:   7,
                               color: 'orange'
    @serif      = Kitty.create name:  'Serif',
                               breed: 'Siberian',
                               age:   5,
                               color: 'grey'
    [@kitty_paws, @nate, @jinxii, @italics, @serif]. each {|k| k.reload}
  end

  ### 

  it 'should pass a basic sanity check' do
    Kitty.count.should == 5
  end

  it 'should be able to select all kitties' do
    Kitty.all.map(&:name).should include('Kitty Paws')
    Kitty.all.map(&:name).should include('Nate')
    Kitty.all.map(&:name).should include('Jinxii')
    Kitty.all.map(&:name).should include('Italics')
    Kitty.all.map(&:name).should include('Serif')
  end

  context 'with no fields' do
    it 'should return the empty set with no conditions given' do
      Kitty.where().should be_empty
    end
  end

  context 'with one field' do
    it 'should be able to find by an indexed field using where()' do
      Kitty.where(:name => 'Nate').to_a.map(&:name).should include('Nate')
    end

    it 'should be able to find by a non-indexed field using where()' do
      Kitty.where(:breed => 'Siberian').to_a.map(&:name).should include('Italics')
      Kitty.where(:breed => 'Siberian').to_a.map(&:name).should include('Serif')
    end
  end

  it 'should be able to find by two indexed fields at once' do
    kitty = Kitty.where(:name => "Kitty Paws", :color => "orange")
    kitty.count.should == 1
    kitty.first.name.should == "Kitty Paws"
  end

  it 'should be able to find by two non-indexed fields at once' do
    # :breed and :age are not indexed
    Kitty.where(:breed => "Domestic shorthair", :age => 17).count.should == 1
  end

  it 'should be able to find by a mix of indexed and non-indexed fields' do
    # :color is indexed, :breed is not
    Kitty.where(:color => "orange").count.should == 2
    Kitty.where(:breed => "Siberian").count.should == 2
    Kitty.where(:color => "orange", :breed => "Siberian").count.should == 1
    Kitty.where(:color => "orange", :breed => "Siberian").first.name.should == "Italics"
  end

  ###

  after :all do
    Redis.new.flushall
    Ampere.connect
  end
end

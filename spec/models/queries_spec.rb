require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe 'queries', :queries => true do
  before :all do
    Redis.new.flushall
    Ampere.connect
    
    class Kitty < Ampere::Model
      field :name
      field :breed
      
      index :name
    end
    
    @kitty_paws = {
      name: 'Kitty Paws',
      breed: 'Domestic shorthair'
    }
    @nate = {
      name:  'Nate',
      breed: 'Domestic shorthair'
    }
    @jinxii = {
      name:  'Jinxii',
      breed: 'Chartreux'
    }
    @italics = {
      name:  'Italics',
      breed: 'Siberian'
    }
    @serif = {
      name:  'Serif',
      breed: 'Siberian'
    }
    [@kitty_paws, @nate, @jinxii, @italics, @serif]. each {|hash| Kitty.create hash}
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
  
  context 'with one field' do
    it 'should be able to find by an indexed field using where()' do
      Kitty.where(:name => 'Nate').map(&:name).should include('Nate')
    end
  
    it 'should be able to find by a non-indexed field using where()' do
      Kitty.where(:breed => 'Siberian').map(&:name).should include('Italics')
      Kitty.where(:breed => 'Siberian').map(&:name).should include('Serif')
    end
  end
  
  it 'should be able to find by two indexed fields at once' do
    pending
  end
  
  it 'should be able to find by two non-indexed fields at once' do
    pending
  end
  
  it 'should be able to find by a mix of indexed and non-indexed fields' do
    pending
  end
  
  ###
  
  after :all do
    Redis.new.flushall
    Ampere.connect
  end
end

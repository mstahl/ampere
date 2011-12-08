require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe "Model indices", :indices => true do
  before :all do
    Redis.new.flushall
    Ampere.connect

    class Student < Ampere::Model
      field :first_name
      field :last_name
      field :student_id_num
      
      index :last_name
      index :student_id_num
    end
    
    @a = Student.create :first_name     => "Hannibal",
                        :last_name      => "Smith",
                        :student_id_num => "1001"
    @b = Student.create :first_name     => "Cindy",
                        :last_name      => "Smith",
                        :student_id_num => "1002"
    @c = Student.create :first_name     => "Emmanuel",
                        :last_name      => "Goldstein",
                        :student_id_num => "1003"
  end
  
  ###
  
  it 'should find an array of values for a non-unique index' do
    smiths = Student.where(:last_name => "Smith")
    smiths.should_not be_empty
    smiths.map(&:first_name).should include("Hannibal")
    smiths.map(&:first_name).should include("Cindy")
  end
  
  it 'should find a single value for a unique index' do
    smiths = Student.where(:student_id_num => "1003")
    smiths.should_not be_empty
    smiths.first.first_name.should == "Emmanuel"
  end
  
  it 'should refuse to create an index on a field that does not exist' do
    (->{
      class Student < Ampere::Model
        index :this_field_does_not_exist
      end
    }).should raise_error
  end
  
  ###
  
  after :all do
    Redis.new.flushall
    Ampere.disconnect
  end
end
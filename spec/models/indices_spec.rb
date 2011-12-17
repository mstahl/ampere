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
  
  it 'should know about its own indices' do
    Student.indices.should include(:last_name)
    Student.indices.should_not include(:first_name)
    Student.indices.should include(:student_id_num)
  end
  
  it 'should find an array of values for a non-unique index' do
    smiths = Student.where(:last_name => "Smith")
    smiths.should_not be_empty
    smiths.map(&:first_name).should include("Hannibal")
    smiths.map(&:first_name).should include("Cindy")
  end
  
  it 'should find a single value for a unique index' do
    emmanuel = Student.where(:student_id_num => "1003")
    emmanuel.should_not be_empty
    emmanuel.first.first_name.should == "Emmanuel"
  end
  
  it 'should refuse to create an index on a field that does not exist' do
    (->{
      class Student < Ampere::Model
        index :this_field_does_not_exist
      end
    }).should raise_error
  end
  
  it 'should enforce the uniqueness of unique single-field indices' do
    pending
  end
  
  context 'compound indices' do
    before :all do
      class Professor < Ampere::Model
        field :first_name
        field :last_name
        field :employee_id_number
        
        index :employee_id_number
        index [:last_name, :first_name]
      end
    end
    
    ###
    
    it 'should define compound indices' do
      Professor.indices.should include([:first_name, :last_name])

      Ampere.connection.exists("ampere.index.professor.first_name:last_name").should be_false
      Professor.create :first_name         => "Warren",
                       :last_name          => "Satterfield",
                       :employee_id_number => "31415926"
      Professor.count.should == 1
      Ampere.connection.exists("ampere.index.professor.first_name:last_name").should be_true
    end
    
    it 'should be able to search on both fields of a compound index' do
      Professor.create :first_name         => "Ava",
                       :last_name          => "Jenkins",
                       :employee_id_number => "31415927"
      Professor.create :first_name         => "Lazaro",
                       :last_name          => "Adams",
                       :employee_id_number => "31415928"
      Professor.create :first_name         => "Brandi",
                       :last_name          => "O'Kon",
                       :employee_id_number => "31415929"

      brandi = Professor.where(:first_name => "Brandi", :last_name => "O'Kon")
      brandi.count.should == 1
      brandi.first.employee_id_number.should == "31415929"
    end
    
    it 'should still be able to search on just one field of a compound index' do
      pending
    end
  end
  
  ###
  
  after :all do
    Redis.new.flushall
    Ampere.disconnect
  end
end
require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe 'Validations', :validations => true do
  before :all do
    class Person
      include Ampere::Model
    
      field :first_name
      field :last_name
      field :email
    
      validates_presence_of :last_name
      validates_format_of :email, :with => /\A\w+@\w+\.com\Z/i
    end
  
  end

  it 'should validate presence of items' do
    alice = Person.new :first_name => 'Alice',
                       :last_name  => 'Steel',
                       :email      => 'alice@steel.com'
    bob   = Person.new :first_name => 'Bob',
                       :email      => 'bob@bob.com'
    alice.should be_valid
    alice.errors.should be_empty
    bob.should be_invalid
    bob.errors.should_not be_empty
  end

  it 'should validate format of items' do
    charlie = Person.new :first_name => 'Charlie',
                         :last_name  => 'Steel',
                         :email      => 'c h a r l i e @ charlie .com'
    charlie.should_not be_valid
  end

  # Since this is accomplished by including a module, what is being tested here
  # is that the module got included correctly and works. For testing of all the
  # other kinds of validations, run the tests for ActiveModel::Validations.
end

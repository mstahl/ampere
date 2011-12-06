require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe "Model relationships", :mode => true, :relationships => true do
  before :all do
    Redis.new.flushall
    Ampere.connect
    
    # Here are some classes that are related to each ohter in various ways
    class Post < Ampere::Model
      field :title
      field :content
      
      has_one :category
      has_many :comments
      belongs_to :user
    end
    
    class Category < Ampere::Model
      field :name
    end
    
    class Comment < Ampere::Model
      field :content

      belongs_to :post
    end
    
    # These are used by the has_one/belongs_to example below
    class Car < Ampere::Model
      field :make
      field :model
      field :year
      
      has_one :engine
    end
    
    class Engine < Ampere::Model
      field :displacement
      field :model
      field :manufacturer
    end
  end
  
  ###
  
  context 'has_one relationships' do
    it 'can store a relationship to one model instance from another using an attr_accessor' do
      category = Category.create :name => "Kitties"
      post     = Post.create :title    => "Kitties are awesome",
                             :content  => "That is all."
      post.category_id = category.id
      post.category_id.should == category.id
    end
    
    it 'can store a relationship to one model instance from another using custom accessor methods' do
      category = Category.create :name => "Kitties"
      post     = Post.create :title    => "Kitties are awesome",
                             :content  => "That is all."
      post.category = category
      post.category.should == category
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


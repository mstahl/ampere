require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe "Model relationships", :mode => true, :relationships => true do
  before :all do
    Redis.new.flushall
    Ampere.connect
    
    class Category < Ampere::Model
      field :name
    end
    
    class Post < Ampere::Model
      field :title
      field :content
      
      has_one :category
      has_many :comments
      belongs_to :user
    end
    
    class Comment < Ampere::Model
      field :content

      belongs_to :post
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
  end
  
  context 'has_many relationships' do
  end
  
  ###
  
  after :all do
    Redis.new.flushall
  end
end


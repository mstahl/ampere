require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe "Base models", :model => true do
  context "by themselves" do
    before :all do
      Ampere.connect
      
      # Clear out Redis
      Redis.new.flushall
      
      # Define a model class here.
      class Post < Ampere::Model
        field :title, String
        field :byline, String
        field :content, String
      end
      
    end
    
    # # #
    
    it "should define attr accessors and suchlike" do
      post = Post.new
      post.should respond_to(:title)
      post.should respond_to(:"title=")
      post.should respond_to(:byline)
      post.should respond_to(:"byline=")
      post.should respond_to(:content)
      post.should respond_to(:"content=")
    end
    
    it "should know about its own fields" do
      Post.fields.should include(:title)
      Post.fields.should include(:byline)
      Post.fields.should include(:content)
    end
    
    it "should raise an exception when you try to set a field that doesn't exist" do
      (->{Post.new :shazbot => "This isn't the right key"}).should raise_error
    end
    
    it "should have a 'new' method that works like we'd expect" do
      post = Post.new :title   => "Amish Give Up - 'This is bullshit!', Elders Say",
                      :byline  => "The Onion",
                      :content => %{
                        Lorem ipsum dolor sit amet, consectetur adipisicing
                        elit, sed do eiusmod tempor incididunt ut labore et
                        dolore magna aliqua.
                      }
      post.title.should   == "Amish Give Up - 'This is bullshit!', Elders Say"
      post.byline.should  == "The Onion"
      post.content.should =~ /Lorem ipsum dolor/
    end
    
    it "should be able to convert itself to a hash" do
      post = Post.new :title   => "A title",
                      :byline  => "Max",
                      :content => "Some content"
      hash = post.to_hash
      hash[:title].should   == "A title"
      hash[:byline].should  == "Max"
      hash[:content].should == "Some content"
    end
    
    it "should have a 'save' and 'reload' method that work like we'd expect" do
      post = Post.new :title   => "A title",
                      :byline  => "Max",
                      :content => "Some content"

      post.save.should be_true

      post.reload
      post.title.should   == "A title"
      post.byline.should  == "Max"
      post.content.should == "Some content"
    end

    it "should be able to tell when it's new" do
      post = Post.new :title   => "A title",
                      :byline  => "Max",
                      :content => "Some content"
      post.new?.should be_true
      post.save
      post.new?.should be_false
    end
    
    it "should be destroyed" do
      pending
    end
    
    it "should be findable by ID" do
      post = Post.create :title   => "foo",
                         :byline  => "bar",
                         :content => "baz"
      Post.find(post.id).should == post
      # Since we're using GUIDs, this should also be true:
      Model.find(post.id).should == post
    end
    
    it "should be findable by title" do
      pending
    end
    
    # # #
    
    after :all do
      # Clear out Redis
      Redis.new.flushall
      Ampere.disconnect
    end
    
  end
  
end
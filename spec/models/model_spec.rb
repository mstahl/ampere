require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe "Base models" do
  context "by themselves" do
    before :all do
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
                        dolore magna aliqua. Ut enim ad minim veniam, quis
                        nostrud exercitation ullamco laboris nisi ut aliquip ex
                        ea commodo consequat. Duis aute irure dolor in
                        reprehenderit in voluptate velit esse cillum dolore eu
                        fugiat nulla pariatur. Excepteur sint occaecat
                        cupidatat non proident, sunt in culpa qui officia
                        deserunt mollit anim id est laborum.
                      }
      post.title.should == "Amish Give Up - 'This is bullshit!', Elders Say"
      post.byline.should == "The Onion"
      post.content.should =~ /Lorem ipsum dolor/
    end
    
    it "should have a 'save' method that works like we'd expect" do
      pending
    end
    
    it "should be destroyed" do
      pending
    end
    
    it "should be findable by ID" do
      pending
    end
    
    it "should be findable by title" do
      pending
    end
    
    # # #
    
    after :all do
      # Clear out Redis
      Redis.new.flushall
    end
    
  end
  
end
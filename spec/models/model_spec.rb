require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe "Base models", :model => true do
  context "by themselves" do
    before :all do
      Ampere.connect
      
      # Clear out Redis
      Redis.new.flushall
      
      # Define a model class here.
      class Post < Ampere::Model
        field :title
        field :byline
        field :content
      end
      
    end
    
    # # #

    context 'fields' do
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
    
      it "should have default values definable" do
        class Comment < Ampere::Model
          field :subject, :default => "No subject"
          field :content
        end
      
        comment = Comment.new
        comment.subject.should == "No subject"
        comment.content.should be_nil
      end
    
      it "should raise an exception when you try to set a field that doesn't exist" do
        (->{Post.new :shazbot => "This isn't the right key"}).should raise_error
      end
      
      context 'types', :types => true do
        before :all do
          # Just adding a field with a type to Post
          class Post < Ampere::Model
            field :pageviews, :type => Integer, :default => 0
          end
        end
        
        it "should set field types for fields that have a type" do
          Post.field_types.should_not be_nil
          Post.field_types[:pageviews].should_not be_nil
          Post.field_types[:pageviews].should == 'Integer'
        end
        
        it "shouldn't care what the value types are assigned to a field with no type defined" do
          # Assign an int to the :title of a Post.
          (->{
            Post.create :title     => 1234,
                        :byline    => "",
                        :content   => "",
                        :pageviews => 1234
            
            
          }).should_not raise_error
          
          # Assign a string to the :title of a Post.
          (->{
            Post.create :title     => "1234",
                        :byline    => "",
                        :content   => "",
                        :pageviews => 1234
          }).should_not raise_error
        end
        
        it "should, given a field's type, only accept values for that field of that type", wip:true do
          post = Post.create :title     => "",
                             :byline    => "",
                             :content   => "",
                             :pageviews => 1234
          
          # Try to assign a string to :year, raising an error.
          (->{post.pageviews = "this is not an integer"}).should raise_error
          (->{post.pageviews = 4321}).should_not raise_error
        end
      end
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
      hash = post.attributes
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
    
    it "should refuse to reload a new record, that hasn't yet been saved" do
      post = Post.new :title   => "A title",
                      :byline  => "Max",
                      :content => "Some content"
      (->{post.reload}).should raise_error
    end
    
    it "should be able to tell when two records are equivalent" do
      foo = Post.create :title => "Kitties!", :byline => "Max", :content => "Kitties are awesome."
      bar = Post.create :title => "Doggies!", :byline => "Max", :content => "Doggies are cool."
      
      foo.should == foo
      foo.should_not == bar
      
      foo.should eql(foo)
      foo.should_not eql(bar)
    end
    
    it "should also be able to determine the hash of a record, for equivalence testing" do
      Post.new(title: "Guinea Pigs", byline: "Max", content: "Guinea pigs are super cute.").hash.is_a?(Fixnum).should be_true
    end

    it "should be able to tell when it's new" do
      post = Post.new :title   => "A title",
                      :byline  => "Max",
                      :content => "Some content"
      post.new?.should be_true
      post.save
      post.new?.should be_false
    end
    
    it "should be deleteable from the model class" do
      post = Post.create :title   => "This post should be deleted",
                         :byline  => "because it's awful",
                         :content => "and it doesn't even make sense."
      id = post.id
      post.should_not be_nil
      Post.delete(id).should == 1
      Post.find(id).should be_nil
    end
    
    it "should be destroyable by itself" do
      another_post = Post.create :title   => "This one too, probably.",
                                 :byline  => "Just seems like one big",
                                 :content => "non sequitor."
      id = another_post.id
      another_post.destroy.should == 1
      Post.find(id).should be_nil
    end
    
    it "should be findable by ID" do
      post = Post.new :title   => "foo",
                      :byline  => "bar",
                      :content => "baz"
      post.save
      Post.find(post.id).should == post
      # Since we're using GUIDs, this should also be true:
      post2 = Post.find(post.id)
      
      post.title.should   == post2.title
      post.byline.should  == post2.byline
      post.content.should == post2.content
    end

    it "should be able to save itself upon creation" do
      post = Post.create :title   => "Another title",
                         :byline  => "Max",
                         :content => "Some other content"
      Post.find(post.id).should == post
    end
    
    # # #
    
    after :all do
      # Clear out Redis
      Redis.new.flushall
      Ampere.disconnect
    end
    
  end
  
end
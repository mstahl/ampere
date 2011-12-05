require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe "Model indices", :indices => true do
  before :all do
    Redis.new.flushall
    Ampere.connect
    class Widget < Ampere::Model
      field :foo
      field :bar
      field :baz
      
      index :foo
      index :bar
      index :baz
    end
    
    @a = Widget.new :foo => "foo",
                    :bar => "foo",
                    :baz => "foo"
    @b = Widget.new :foo => "bar",
                    :bar => "bar",
                    :baz => "baz"     # Same as @c.baz
    @c = Widget.new :foo => "baz",
                    :bar => "baz",
                    :baz => "baz"     # Same as @b.baz
  end
  
  ###
  
  context 'non-unique indices' do
    it 'should default to non-unique' do
      pending
    end
    
    it 'should find an array of values for a non-unique index' do
      widgets = Widget.where(:baz => "baz").map(&:to_hash)
      widgets.should include(@b.to_hash)
      widgets.should include(@c.to_hash)
    end
    
  end
  
  context 'unique indices' do
    pending
  end
  
  ###
  
  after :all do
    Redis.new.flushall
    Ampere.disconnect
  end
end
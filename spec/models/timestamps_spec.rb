describe Ampere::Timestamps do
  before :all do
    Ampere.connect
  
    Ampere.connection.flushall
  
    class Comment
      include Ampere::Model
      include Ampere::Timestamps
    
      field :body
    end
  end

  context 'when included in models' do
    it 'sets created_at for newly-created record' do
      Timecop.freeze(Time.now) do
        time = Time.now
      
        c = Comment.create body: "I am intrigued by your ideas, and would like to subscribe to your newsletter."
        c.created_at.should eq(time)
        c.updated_at.should eq(time)
      end
    end
  
    it 'sets updated_at when changing records' do
      c = Comment.create body: "I am intrigued by your ideas, and would like to subscribe to your newsletter."
      created_at = c.created_at
    
      time = 0
    
      Timecop.freeze(Time.now + 30) do
        time = Time.now
      
        c.body = "Theodore Roosevelt riding a moose, therefore your argument is invalid."
        c.save
      end
    
      c.updated_at.should eq(time)
      c.created_at.should eq(created_at)
    end
  
  end

end

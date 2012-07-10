require File.join(File.dirname(__FILE__), "..", "spec_helper.rb")

describe "Volatility", volatility:true do
  
  # An example use of volatile models: tracking ephemeral data on ad campaigns.
  class Visit
    include Ampere::Model
    
    field :visitor_id
    field :campaign
  end
  
  context "in initializer", wip:true do
    it 'should initialize with a time to expire at in seconds since the epoch' do
      (->{
        Visit.new visitor_id: 1234, campaign: 'social-networking', expire_at: (Time.now + 1)
      }).should_not raise_error
    end
    
    it 'should initialize with a time to expire at in milliseconds since the epoch' do
      pending "Not sure how to get at the PEXPIREAT command in Ruby"
      (->{
        Visit.new visitor_id: 1234, campaign: 'social-networking', expire_at_ms: (Time.now.to_f * 1000 + 1000)
      }).should_not raise_error
    end
    
    it 'should initialize with a time to live in seconds' do
      (->{
        Visit.new visitor_id: 1234, campaign: 'social-networking', expire_in: (Time.now + 1)
      }).should_not raise_error
    end
    
    it 'should initialize with a time to live in milliseconds' do
      pending "Not sure how to get at the PEXPIRE command in Ruby"
      (->{
        Visit.new visitor_id: 1234, campaign: 'social-networking', expire_in_ms: (Time.now.to_f * 1000 + 1000)
      }).should_not raise_error
    end
  end
  
  context Ampere::Model do
    before(:all) { Timecop.freeze Time.now }
    
    let(:persistent_record)     { Visit.new visitor_id: 1, campaign: 'a campaign' }
    let(:volatile_record_at)    { Visit.new visitor_id: 1, campaign: 'a campaign', expire_at: (Time.now + 3600) }
    let(:volatile_record_in)    { Visit.new visitor_id: 1, campaign: 'a campaign', expire_in: 10 }
    let(:volatile_record_at_ms) { Visit.new visitor_id: 1, campaign: 'a campaign', expire_at_ms: (Time.now + 3600000) }
    let(:volatile_record_in_ms) { Visit.new visitor_id: 1, campaign: 'a campaign', expire_in_ms: 10 }
    
    describe "#volatile?", focus:true do
      it 'should return true for volatile records' do
        volatile_record_at.should be_volatile
        volatile_record_in.should be_volatile
      end
      
      it 'should return false for persistent records' do
        persistent_record.should_not be_volatile
      end
    end
    
    describe "#persistent?", focus:true do
      it 'should return false for volatile records' do
        volatile_record_at.should_not be_persistent
        volatile_record_in.should_not be_persistent
      end
      
      it 'should return true for persistent records' do
        persistent_record.should be_persistent
      end
    end
    
    describe "#ttl" do
      pending "Need separate tests for _at and _in expirations"
      
      it 'should return time-to-live in seconds for volatile records' do
        pending "Need separate tests for _at and _in expirations"
        volatile_record_at.ttl.should eq(3600)
      end
      
      it 'should return nil for non-volatile records' do
        pending "Need separate tests for _at and _in expirations"
        persistent_record.ttl.should eq(nil)
      end
    end
    
    describe "#ttl_ms" do
      it 'should return time-to-live in milliseconds for volatile records' do
        pending "Need separate tests for _at and _in expirations"
        volatile_record.ttl_ms.should eq(3_600_000)
      end
      
      it 'should return nil for non-volatile records' do
        pending "Need separate tests for _at and _in expirations"
        persistent_record.ttl_ms.should eq(nil)
      end
    end
    
    after(:all) { Timecop.return }
  end
  
  context "expiration" do
    it 'should not expire non-volatile entries' do
      pending "Requires all the other tests to pass"
      persistent_visit = Visit.new visitor_id: 3456, campaign: 'bus ad'
      persistent_visit.should_not be_expired
    end
    
    it 'should be expired? when past its expiration' do
      pending "Requires all the other tests to pass"
      volatile_visit = Visit.new visitor_id: 2345, campaign: 'word of mouth', expire_at: (Time.now + 3600)
    
      Timecop.freeze(Time.now + 7200) do
        volatile_visit.should be_expired
      end
    end
  end
  
end


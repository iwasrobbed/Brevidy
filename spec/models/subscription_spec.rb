require 'spec_helper'

describe Subscription do
  before do
    @channel = FactoryGirl.create(:channel)
    @publisher = @channel.user
    @subscriber = FactoryGirl.create(:user)
    
    @subscription = @subscriber.subscriptions.build
    @subscription.publisher_id = @publisher.id
    @subscription.channel_id = @channel.id
  end
  
  describe "mass-assignment protection" do
    it "should protect attributes" do
      @subscription.save
      @other_user = FactoryGirl.create(:user)
      @other_channel = FactoryGirl.create(:channel)
      @subscription.should_not allow_mass_assignment_of(:publisher_id => @other_user.id)
      @subscription.should_not allow_mass_assignment_of(:subscriber_id => @other_user.id)
      @subscription.should_not allow_mass_assignment_of(:channel_id => @other_channel.id)
    end  
  end
  
  describe "for a valid request" do
    it "should create a new instance given valid attributes" do
      @subscription.save
      @subscription.should be_valid
    end
    it "should destroy any pending channel_request objects (since they were approved)" do
      channel_request = ChannelRequest.new
      channel_request.user_id = @subscriber.id
      channel_request.channel_id = @channel.id
      channel_request.save
      channel_request.should be_valid
      
      @subscription.save
      @subscription.should be_valid
      
      ChannelRequest.where(:user_id => @subscriber.id, :channel_id => @channel.id).first.should be_nil
    end
  end
  
  describe "for an invalid request" do
    it "should require a subscriber_id" do
      @subscription.subscriber_id = nil
      @subscription.channel_id = @channel.id
      @subscription.save
      @subscription.should_not be_valid
    end
    it "should require a publisher_id" do
      @subscription.publisher_id = nil
      @subscription.channel_id = @channel.id
      @subscription.save
      @subscription.should_not be_valid
    end
    it "should require a channel_id" do
      @subscription.channel_id = nil
      @subscription.save
      @subscription.should_not be_valid
    end
    it "should not allow duplicate :channel_id and :subscriber_id pairs" do
      @subscription.save
      @subscription.should be_valid
      
      @subscription = @subscriber.subscriptions.build
      @subscription.publisher_id = @publisher.id
      @subscription.channel_id = @channel.id
      @subscription.save
      @subscription.should_not be_valid
    end
  end

end


# == Schema Information
#
# Table name: subscriptions
#
#  id            :integer         not null, primary key
#  subscriber_id :integer
#  publisher_id  :integer
#  created_at    :datetime
#  updated_at    :datetime
#  channel_id    :integer
#  collaborator  :boolean         default(FALSE)
#


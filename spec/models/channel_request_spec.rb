require 'spec_helper'

describe ChannelRequest do
  before do
    @channel ||= FactoryGirl.create(:channel)
    @channel_owner = @channel.user
    @user ||= FactoryGirl.create(:user)
  end
  describe "AR associations" do
    it "should respond to the associations" do
      channel_request = ChannelRequest.new
      channel_request.user_id = @user.id
      channel_request.channel_id = @channel.id
      channel_request.save
      channel_request.should be_valid
      
      channel_request.should respond_to(:user)
      channel_request.should respond_to(:channel)
    end
  end
  describe "mass-assignment protection" do
    it "should not allow mass-assignment of protected attributes" do
      channel_request = ChannelRequest.new
      channel_request.user_id = @user.id
      channel_request.channel_id = @channel.id
      channel_request.save
      channel_request.should be_valid
      
      channel_request.should_not allow_mass_assignment_of(:user_id => "1")
      channel_request.should_not allow_mass_assignment_of(:channel_id => "1")
      channel_request.should_not allow_mass_assignment_of(:ignored => "true")
      channel_request.should_not allow_mass_assignment_of(:token => "asdfasdf")
    end
  end
  describe "for an invalid request" do
    it "should not save without :channel_id" do
      channel_request = ChannelRequest.new
      channel_request.user_id = @user.id
      channel_request.save
      channel_request.should_not be_valid
    end
    it "should not save without :user_id" do
      channel_request = ChannelRequest.new
      channel_request.channel_id = @channel.id
      channel_request.save
      channel_request.should_not be_valid
    end
    it "should not allow duplicate :channel_id and :user_id pairs" do
      # create first record and make sure it's valid
      channel_request = ChannelRequest.new
      channel_request.user_id = @user.id
      channel_request.channel_id = @channel.id
      channel_request.save
      channel_request.should be_valid
      
      # now duplicate it; this one should not be valid
      channel_request = ChannelRequest.new
      channel_request.user_id = @user.id
      channel_request.channel_id = @channel.id
      channel_request.save
      channel_request.should_not be_valid
    end
    it "should not allow a user to create a request to their own channel" do
      # create a record as the channel owner
      channel_request = ChannelRequest.new
      channel_request.user_id = @channel_owner.id
      channel_request.channel_id = @channel.id
      channel_request.save
      channel_request.should_not be_valid
      channel_request.errors[:user_id].to_s.should =~ /You cannot request access to your own channel/i
    end
  end
  describe "for a valid request" do
    before do
      @channel_request = ChannelRequest.new
      @channel_request.user_id = @user.id
      @channel_request.channel_id = @channel.id
      @channel_request.save
    end
    it "should save properly" do
      @channel_request.should be_valid
    end
    it "should generate a token" do
      @channel_request.token.should_not be_nil
    end
  end
end



# == Schema Information
#
# Table name: channel_requests
#
#  id         :integer         not null, primary key
#  channel_id :integer
#  user_id    :integer
#  token      :string(255)
#  ignored    :boolean         default(FALSE)
#  created_at :datetime
#  updated_at :datetime
#


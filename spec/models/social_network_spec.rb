require 'spec_helper'

describe SocialNetwork do
  it "should save successfully with proper params" do
    sn_fb = SocialNetwork.create(:user_id => 1, :uid => "1234567890", :provider => "facebook", :token => "token")
    sn_fb.should be_valid
    sn_tw = SocialNetwork.create(:user_id => 1, :uid => "1234567890", :provider => "twitter", :token => "token", :token_secret => "token secret")
    sn_tw.should be_valid
  end
  it "should not save without passing in :user_id" do
    sn = SocialNetwork.create(:user_id => nil, :uid => "1234567890", :provider => "facebook", :token => "token")
    sn.should_not be_valid
  end
  it "should not save without passing in :uid" do
    sn = SocialNetwork.create(:user_id => 1, :uid => nil, :provider => "facebook", :token => "token")
    sn.should_not be_valid
  end
  it "should not save without passing in :provider" do
    sn = SocialNetwork.create(:user_id => 1, :uid => "1234567890", :provider => nil, :token => "token")
    sn.should_not be_valid
  end
  it "should save without passing in :token (it is only used for posting content on behalf of user)" do
    sn = SocialNetwork.create(:user_id => 1, :uid => "1234567890", :provider => "facebook", :token => nil)
    sn.should be_valid
  end
  it "should save without passing in :token_secret (only necessary for Twitter)" do
    sn = SocialNetwork.create(:user_id => 1, :uid => "1234567890", :provider => "facebook", :token => "token", :token_secret => nil)
    sn.should be_valid
  end
  it "should not save unless provider is either Facebook or Twitter" do
    sn = SocialNetwork.create(:user_id => 1, :uid => "1234567890", :provider => "linkedin", :token => "token")
    sn.should_not be_valid
  end
  it "should verify the uid and provider combination are unique" do
    sn = SocialNetwork.create(:user_id => 1, :uid => "1234567890", :provider => "facebook", :token => "token")
    sn.should be_valid
    
    # try to create the same record
    sn = SocialNetwork.create(:user_id => 1, :uid => "1234567890", :provider => "facebook", :token => "token")
    sn.should_not be_valid
  end
end






# == Schema Information
#
# Table name: social_networks
#
#  id           :integer         not null, primary key
#  uid          :string(255)
#  provider     :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  token        :string(255)
#  user_id      :integer
#  token_secret :string(255)
#


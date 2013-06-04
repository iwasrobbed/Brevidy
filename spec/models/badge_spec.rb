require 'spec_helper'

describe Badge do
  before do
    @user = FactoryGirl.create(:user)
    @video = FactoryGirl.create(:video)
    @icon = FactoryGirl.create(:icon) 
  end
  describe "for an invalid request" do
    it "should not save without passing in :video_id" do
      badge = Badge.new(:badge_type => @icon.id)
      badge.video_id = nil
      badge.badge_from = @user.id
      badge.save
      badge.should_not be_valid
    end
    it "should not save without passing in :badge_type" do
      badge = Badge.new(:badge_type => nil)
      badge.video_id = @video.id
      badge.badge_from = @user.id
      badge.save
      badge.should_not be_valid
    end
    it "should not save without passing in :badge_from" do
      badge = Badge.new(:badge_type => @icon.id)
      badge.video_id = @video.id
      badge.badge_from = nil
      badge.save
      badge.should_not be_valid
    end
  end
  describe "for a valid request" do
    it "should save properly" do
      badge = Badge.new(:badge_type => @icon.id)
      badge.video_id = @video.id
      badge.badge_from = @user.id
      badge.save
      badge.should be_valid
    end
  end
end


# == Schema Information
#
# Table name: badges
#
#  id         :integer         not null, primary key
#  video_id   :integer
#  badge_type :integer
#  badge_from :integer
#  created_at :datetime
#  updated_at :datetime
#


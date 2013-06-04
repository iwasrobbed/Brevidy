require 'spec_helper'

describe Comment do
  before do
    @user = FactoryGirl.create(:user)
    @video = FactoryGirl.create(:video)
  end
  describe "for an invalid request" do
    it "should not save without passing in :video_id" do
      comment = Comment.new(:content => "Weeee")
      comment.video_id = nil
      comment.user_id = @user.id
      comment.save
      
      comment.should_not be_valid
    end
    it "should not save without passing in :content" do
      comment = Comment.new(:content => nil)
      comment.video_id = @video.id
      comment.user_id = @user.id
      comment.save
      
      comment.should_not be_valid
    end
    it "should not save without passing in :user_id" do
      comment = Comment.new(:content => "Weeee")
      comment.video_id = @video.id
      comment.user_id = nil
      comment.save
      
      comment.should_not be_valid
    end
    it "should not save with a comment length of more than 2500 characters" do
      comment_content = "a" * 2501
      comment = Comment.new(:content => comment_content)
      comment.video_id = @video.id
      comment.user_id = @user.id
      comment.save
      
      comment.should_not be_valid
    end
  end
  describe "for a valid request" do
    it "should save properly" do
      comment = Comment.new(:content => "Weeee")
      comment.video_id = @video.id
      comment.user_id = @user.id
      comment.save
      
      comment.should be_valid
    end
  end
end

# == Schema Information
#
# Table name: comments
#
#  id         :integer         not null, primary key
#  video_id   :integer
#  created_at :datetime
#  updated_at :datetime
#  content    :text
#  user_id    :integer
#


require 'spec_helper'

describe Video do
  
  it "should have a title" do
    video = FactoryGirl.build(:video, :title => nil)
    video.save
    video.should_not be_valid
  end
  
  it "should not save if the title is greater than 75 characters" do
    # give it too long of a title
    # use .build since by default Factory Girl uses .save! which throws
    # a validation exception and causes the test to fail
    video = FactoryGirl.build(:video, :title => "a" * 76)
    video.save
    video.should_not be_valid
  end
  
  it "doesn't have to have a description" do
    video = FactoryGirl.create(:video, :description => nil)
    video.description.should be_nil
    video.should be_valid
  end
  
  it "should not save if the description is greather than 1000 characters" do
    # give it too long of a description
    # use .build since by default Factory Girl uses .save! which throws
    # a validation exception and causes the test to fail
    video = FactoryGirl.build(:video, :description => "a" * 1001)
    video.save
    video.should_not be_valid
  end
  
  it "should have a selected thumbnail within the range 0..3" do
    # give it a selected thumbnail outside the range
    video = FactoryGirl.build(:video, :selected_thumbnail => 5)
    video.save
    video.should_not be_valid
    
    # now give it a valid one
    video = FactoryGirl.build(:video, :selected_thumbnail => 3)
    video.save
    video.should be_valid
  end
  
  it "should belong to a user" do
    video = FactoryGirl.create(:video)
    video.user.should_not be_nil
  end
end


# == Schema Information
#
# Table name: videos
#
#  id                 :integer         not null, primary key
#  user_id            :integer
#  created_at         :datetime
#  updated_at         :datetime
#  delta              :boolean         default(TRUE), not null
#  selected_thumbnail :integer         default(0)
#  public_token       :string(255)
#  send_to_facebook   :boolean         default(FALSE)
#  send_to_twitter    :boolean         default(FALSE)
#  video_graph_id     :integer
#  channel_id         :integer
#  title              :string(255)
#  description        :text
#  featured_at        :datetime
#


require 'spec_helper'

describe VideoFlag do
  before do
    @flag = Flag.create(:reason => "Test reason")
    @video = FactoryGirl.create(:video)
    @flagged_by = test_get_object_owner(@video)
  end
  it "should require a flag_id" do
    video_flag = VideoFlag.create(:flag_id => nil,
                                  :detailed_reason => "Detailed reason")
    video_flag.video_id = @video.id
    video_flag.flagged_by = @flagged_by.id
    video_flag.save
    
    video_flag.should_not be_valid
  end
  it "should require a video_id" do
    video_flag = VideoFlag.create(:flag_id => @flag.id,
                                  :detailed_reason => "Detailed reason")
    video_flag.video_id = nil
    video_flag.flagged_by = @flagged_by.id
    video_flag.save
    
    video_flag.should_not be_valid
  end
  it "should NOT require a flagged_by (for logged in and logged out states)" do
    video_flag = VideoFlag.create(:flag_id => @flag.id,
                                  :detailed_reason => "Detailed reason")
    video_flag.video_id = @video.id
    video_flag.flagged_by = nil
    video_flag.save
  
    video_flag.should be_valid
  end
  it "should NOT require a detailed reason" do
    video_flag = VideoFlag.create(:flag_id => @flag.id,
                                  :detailed_reason => nil)
    video_flag.video_id = @video.id
    video_flag.flagged_by = @flagged_by.id
    video_flag.save
    
    video_flag.should be_valid
  end
end



# == Schema Information
#
# Table name: video_flags
#
#  id              :integer         not null, primary key
#  flag_id         :integer
#  video_id        :integer
#  flagged_by      :integer
#  detailed_reason :text
#  created_at      :datetime
#  updated_at      :datetime
#


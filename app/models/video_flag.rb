class VideoFlag < ActiveRecord::Base
  attr_accessible :flag_id, :detailed_reason
  
  validates :flag_id, :video_id, :presence => true
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


class VideoError < ActiveRecord::Base
end





# == Schema Information
#
# Table name: video_errors
#
#  id             :integer         not null, primary key
#  video_graph_id :integer
#  error_status   :integer
#  created_at     :datetime
#  updated_at     :datetime
#  error_message  :text
#  user_id        :integer
#


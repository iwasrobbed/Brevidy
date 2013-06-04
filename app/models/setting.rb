class Setting < ActiveRecord::Base
  # Defines which attributes can be mass-assigned via a form POST (be careful here)
  attr_accessible :hide_getting_started, :send_email_for_new_badges, 
                  :send_email_for_new_comments, :send_email_for_replies_to_a_prior_comment,
                  :send_email_for_new_subscriber, :send_email_for_featured_video,
                  :send_email_for_private_channel_request, :send_email_for_encoding_completion
  
  belongs_to :user
  
  validates :user_id, :presence => true
  validates :hide_getting_started, :send_email_for_new_badges, 
            :send_email_for_new_comments, :send_email_for_replies_to_a_prior_comment,
            :send_email_for_new_subscriber, :send_email_for_featured_video, 
            :send_email_for_private_channel_request, :send_email_for_encoding_completion,
            :inclusion => { :in => [true, false] }
end


# == Schema Information
#
# Table name: settings
#
#  id                                        :integer         not null, primary key
#  created_at                                :datetime
#  updated_at                                :datetime
#  user_id                                   :integer
#  hide_getting_started                      :boolean         default(FALSE)
#  send_email_for_new_badges                 :boolean         default(TRUE)
#  send_email_for_new_comments               :boolean         default(TRUE)
#  send_email_for_replies_to_a_prior_comment :boolean         default(TRUE)
#  send_email_for_new_subscriber             :boolean         default(TRUE)
#  send_email_for_featured_video             :boolean         default(TRUE)
#  send_email_for_private_channel_request    :boolean         default(TRUE)
#  send_email_for_encoding_completion        :boolean         default(TRUE)
#


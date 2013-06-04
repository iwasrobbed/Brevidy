class Comment < ActiveRecord::Base
  # Defines which attributes can be mass-assigned via a form POST (be careful here)
  attr_accessible :content
  
  # validates these attribute conditions are met
  validates :video_id,  :presence => { :message => "^There was no video ID passed in so we were unable to save your comment" }
  validates :user_id,   :presence => { :message => "^There was no user ID passed in so we were unable to save your comment" }
  validates :content,   :presence => { :message => "^You cannot leave a blank comment" },
                        :length => {  :maximum => 2500,
                                      :message => "^Your comment must be less than 2500 characters in length" }
  
  # Active Record relationships
  belongs_to :video
  
  # Notifies everyone who has commented on the video as well as
  # the video owner that someone has commented on that video
  def notify_all_users_in_the_conversation(current_user, video, video_owner)
    # send e-mail to the video owner unless the person commented on their own video
    # or their notification settings say not to
    unless (video.user_id == self.user_id)
      # for whatever reason, delayed_job won't send the email unless you do it as a delayed_job
      UserMailer.delay(:priority => 40).new_comment(self, video_owner, false) if video_owner.send_email_for_new_comments
      # Add event to activity feed
      UserEvent.delay(:priority => 40).create(:event_type => UserEvent.event_type_value(:comment), 
                                              :event_object_id => self.id,
                                              :user_id => video_owner.id,
                                              :event_creator_id => current_user.id)
    end
    # send e-mail to other people (except the video owner, or the person that just commented) 
    # that have commented on the video unless their notification settings say not to
    users_we_will_not_notify = []
    users_we_will_not_notify << video_owner.id << self.user_id
   
    commenters = Comment.where('video_id = ? AND user_id NOT IN (?)', self.video_id, users_we_will_not_notify).group_by(&:user_id)
    unless commenters.blank?
      commenters.each do |comment_owner_id, comment|
        the_commenter = User.find_by_id(comment_owner_id)
        # for whatever reason, delayed_job won't send the email unless you do it as a delayed_job
        UserMailer.delay(:priority => 40).new_comment(self, the_commenter, true) if the_commenter.send_email_for_replies_to_a_prior_comment
        # Add event to activity feed
        UserEvent.delay(:priority => 40).create(:event_type => UserEvent.event_type_value(:comment_response), 
                                                :event_object_id => self.id,
                                                :user_id => the_commenter.id,
                                                :event_creator_id => current_user.id)
      end
    end
  end
  handle_asynchronously :notify_all_users_in_the_conversation, :priority => 40
  
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


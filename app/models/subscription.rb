class Subscription < ActiveRecord::Base
  attr_protected :publisher_id, :subscriber_id, :channel_id
  
  belongs_to :channel
  # Used for associations in other models
  belongs_to :channels_subscribed_to, :foreign_key => "channel_id", :class_name => "Channel"
  belongs_to :subscriber_people, :foreign_key => "subscriber_id", :class_name => "User"
  
  # validations
  validates :publisher_id, :presence => true
  validates :subscriber_id, :presence => true
  validates :channel_id, :presence => true
  validates_uniqueness_of :channel_id, :scope => :subscriber_id
  
  # Lifecycle actions
  after_create :destroy_channel_request

  private
    # Delete any old channel requests (since they were approved)
    def destroy_channel_request
      channel_request = ChannelRequest.where(:user_id => self.subscriber_id, :channel_id => self.channel_id).first
      channel_request.destroy unless channel_request.blank?
    end
end



# == Schema Information
#
# Table name: subscriptions
#
#  id            :integer         not null, primary key
#  subscriber_id :integer
#  publisher_id  :integer
#  created_at    :datetime
#  updated_at    :datetime
#  channel_id    :integer
#  collaborator  :boolean         default(FALSE)
#


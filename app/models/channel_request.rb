require 'securerandom'

class ChannelRequest < ActiveRecord::Base
  attr_protected :channel_id, :user_id, :ignored, :token
  
  before_validation :generate_token, :on => :create
  validates :channel_id, :user_id, :token, :presence => true
  validates_uniqueness_of :channel_id, :scope => [:user_id]
  validate :request_is_not_from_channel_owner
  
  belongs_to :user
  belongs_to :channel
  
  private
    # Validates the channel owner can't create a request to their own channel
    def request_is_not_from_channel_owner
      channel_owner = Channel.find_by_id(self.channel_id).user rescue nil
      (errors.add(:user_id, "^You cannot request access to your own channel, silly.") if self.user_id == channel_owner.id) unless channel_owner.blank?
    end
    
    # Generate a token for accessing a private channel
    def generate_token
      loop do
        security_token = SecureRandom.base64(50).tr('+/=', 'xyz').first(50)
        break self.token = security_token unless ChannelRequest.where(:token => security_token).exists?
      end
    end
end


# == Schema Information
#
# Table name: channel_requests
#
#  id         :integer         not null, primary key
#  channel_id :integer
#  user_id    :integer
#  token      :string(255)
#  ignored    :boolean         default(FALSE)
#  created_at :datetime
#  updated_at :datetime
#


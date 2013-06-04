class Channel < ActiveRecord::Base
  attr_accessible :title
  
  before_destroy :make_sure_they_dont_destroy_featured_channel
  
  # Validations
  before_validation :strip_title
  before_validation :generate_public_token, :on => :create
  validates :title,   :presence => { :message => "^Please name your channel" },
                      :length => { :maximum => 30, :message => "^Channel name is too long (maximum of 30 characters)" }
  validates_uniqueness_of :title, :scope => [:user_id], 
                                  :case_sensitive => false,
                                  :message => "^You already have a channel with that name"
  validate :featured_channel_stays_public, :user_cant_change_featured_channel_title, :on => :update
  validates_presence_of :public_token, :unless => :featured
  
  belongs_to :user
  has_many :videos, :dependent => :destroy, :order => 'created_at DESC'
  has_many :subscribers, :foreign_key => "channel_id", 
                         :class_name => "Subscription", 
                         :dependent => :destroy
  has_many :subscribers_as_people, :through => :subscribers, :source => :subscriber_people, :order => 'UPPER(name) ASC'
  
  # User requests to access private channels
  has_many :channel_requests, :dependent => :destroy
  
  
  ################
  ## SEO Params ##
  ################
  
  # Creates an SEO friendly slug in the URL
  # i.e. http://brevidy.com/rob/channels/3-my-public-videos
  def to_param
    "#{id}-#{title.parameterize}"
  end
  
  
  #############
  ## Helpers ##
  #############
  
  # Returns 9 videos that have a :ready status
  def videos_for_preview
    self.videos.joins(:video_graph).where(:video_graphs => { :status => VideoGraph.get_status_number(:ready) }).limit(9)
  end
    
    
  #################
  ## Permissions ##
  #################  
  
  # Returns whether or not the given user can access the channel
  def is_accessible_by(current_user)
    return true if !self.private?

    unless current_user.blank?
      return false if Blocking.where(:requesting_user => self.user_id, :blocked_user => current_user.id).exists?
      return true if self.user_id == current_user.id
      return true if current_user.is_subscribed_to?(self)
    end
    
    # If we got this far, they can't access it.
    return false
  end
  
  # Regenerates the public token for a private channel
  def regenerate_public_token!
    self.regenerate_public_token and self.save
  end
  def regenerate_public_token
    loop do
      new_token = SecureRandom.base64(50).tr('+/=', 'xyz').first(50)
      break self.public_token = new_token unless Channel.where(:public_token => new_token).exists?
    end
  end

  
  ###################
  ## Subscriptions ##
  ###################  
  
  def subscribe!(current_user, request_approved = false)
    subscription ||= current_user.subscriptions.new
    subscription.errors.add(:id, "^You cannot subscribe to your own channel.") and return subscription if self.user_id == current_user.id
    subscription.errors.add(:channel_id, "^You are already subscribed to this channel.") and return subscription if Subscription.where(:subscriber_id => current_user.id, :channel_id => self.id).exists?
    
    channel_owner = User.find_by_id(self.user_id)
    if self.private? && request_approved == false
      if ChannelRequest.where(:user_id => current_user.id, :channel_id => self.id).exists?
         subscription.errors.add(:channel_id, "^You have already requested access to this channel.  Please be patient while this person responds to the request.")
      else
        # Add channel request
        channel_request = ChannelRequest.new
        channel_request.user_id = current_user.id
        channel_request.channel_id = self.id
        channel_request.save
        
        # Request permission
        subscription.errors.add(:subscriber_id, "^requesting permission")
        UserMailer.delay.request_channel_approval(current_user, self, channel_request) if channel_owner.send_email_for_private_channel_request
        
        # Add event to activity feed
        UserEvent.delay(:priority => 40).create(:event_type => UserEvent.event_type_value(:channel_request), 
                                                :event_object_id => channel_request.id,
                                                :user_id => self.user_id,
                                                :event_creator_id => current_user.id)
      end
    else
      subscription.subscriber_id = current_user.id
      subscription.publisher_id = self.user_id
      subscription.channel_id = self.id
      subscription.save

      # Send an email to the subscriber if this was a request approval
      UserMailer.delay.private_channel_request_approved(current_user, self) if request_approved
      
      # Send an email to the channel owner about the new subscriber 
      # unless they just approved the subscription request or their settings say not to
      UserMailer.delay.new_subscriber(channel_owner, current_user, self) if channel_owner.send_email_for_new_subscriber && !request_approved
    
      # Add event to activity feed
      UserEvent.delay(:priority => 40).create(:event_type => UserEvent.event_type_value(:subscription), 
                                              :event_object_id => subscription.id,
                                              :user_id => self.user_id,
                                              :event_creator_id => current_user.id)
    end
    
    return subscription
  end
  
  def unsubscribe!(current_user)
    subscription ||=  current_user.subscriptions.where(:channel_id => self.id).first
    if subscription.blank?
      return false
    else
      subscription.destroy
      return true
    end
  end
  
  
  private
    # Populates the public token for a public/private channel
    def generate_public_token
      self.regenerate_public_token unless self.featured?  
    end
    
    # Ensures the featured channel always stays public
    def featured_channel_stays_public
      errors.add(:private, "^You cannot make the featured channel private") if self.featured? && self.private?
    end
    
    # Ensures the featured channel's title always stays the same
    def user_cant_change_featured_channel_title
      errors.add(:title, "^You cannot change the name for the featured videos channel") if self.featured? && self.title != "Featured Videos"
    end
    
    # Prepares params for validations
    def strip_title
      self.title = self.title.strip unless self.title.blank?
    end
    
    # Ensure the user does not destroy the featured channel
    def make_sure_they_dont_destroy_featured_channel
      return false if self.featured?
    end
end




# == Schema Information
#
# Table name: channels
#
#  id           :integer         not null, primary key
#  user_id      :integer
#  title        :string(255)
#  private      :boolean         default(FALSE)
#  featured     :boolean         default(FALSE)
#  created_at   :datetime
#  updated_at   :datetime
#  public_token :string(255)
#  recommended  :boolean         default(FALSE)
#


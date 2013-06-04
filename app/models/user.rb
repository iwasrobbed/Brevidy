require 'digest'

class User < ActiveRecord::Base
  # custom module used for cleaning S3 after new profile images
  include Brevidy::Fog
  # needed for truncate method
  include ActionView::Helpers::TextHelper
  
  # Defines which attributes can be mass-assigned via a form POST (be careful here)
  attr_accessible :name, :email, :password, :gender, :birthday, :location, 
                  :banner_image, :image, :image_status, :username, :background_image_id, :banner_image_id
  
  # user image uploader
  mount_uploader :image, ImageUploader
  mount_uploader :banner_image, BannerUploader
  
  # Lifecycle actions
  after_create :create_username_changed_timestamp, :create_default_channels, :create_profile, 
               :create_default_settings, :create_invitation_link
  before_save :encrypt_password
    
  # Constants
    # sets the standard regular expressions for verification
    NAME_REGEX = /\A[a-z\x20.']+\z/i
    EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    USERNAME_REGEX = /\A_?[a-z]_?(?:[a-z0-9]_?)*\z/i
    USERNAME_LENGTH = 20

    # sets whether users can invite others or not
    USERS_CAN_INVITE_MORE_PEOPLE = true
  
  # Validations
  before_validation :prepare_params_for_validation
  validate :email_address_has_not_been_banned
  
  validates :name,  :presence => true,
                    :format => { :with => NAME_REGEX,
                                 :message => "^Name contains invalid characters." },
                    :length => { :maximum => 30 }
  validates :email, :presence => true,
                    :length => { :maximum => 250 },
                    :format => {  :with => EMAIL_REGEX, 
                                  :message => "^The e-mail address you provided is invalid"},
                                  :uniqueness => { :case_sensitive => false, 
                                  :message => "^There is already an account associated with this email" }
  validates :location,  :length => { :maximum => 50 }
  validates :password,  :presence => true,
                        :length => { :minimum => 6, :maximum => 250 }
  validates :gender,    :allow_nil => true,
                        :allow_blank => true,
                        :inclusion => { :in => ["Male", "Female"] }
  validates :birthday,  :presence => true
  validates_date :birthday, :before => lambda { 13.years.ago },
                            :before_message => "^You must be at least 13 years old to use Brevidy"
  validates :background_image_id, :inclusion => 0..1
  validates :username,  :presence => true,
                        :format => { :with => USERNAME_REGEX,
                                     :message => "^Your username can only contain letters A-Z, numbers 0-9, and underscores." },
                        :length => { :maximum => USERNAME_LENGTH },
                        :uniqueness => { :message => "^That username is not available",
                                         :case_sensitive => false }     
  validate :username_changed_more_than_one_month_ago, :on => :update
  validate :username_is_acceptable
  
  has_one :profile, :dependent => :destroy
    delegate :website, :bio, :interests, :favorite_music, :favorite_movies, :favorite_foods, :favorite_books,
             :favorite_people, :things_i_could_live_without, :one_thing_i_would_change_in_the_world,
             :quotes_to_live_by, :to => :profile
            
  has_many :channels, :dependent => :destroy, :order => 'updated_at DESC'
  has_many :subscriptions, :foreign_key => "subscriber_id", 
                           :dependent => :destroy
  has_many :subscribers, :foreign_key => "publisher_id", 
                         :class_name => "Subscription", 
                         :dependent => :destroy
    has_many :channel_subscriptions, :through => :subscriptions, :source => :channels_subscribed_to
    has_many :subscribers_as_people, :through => :subscribers, :source => :subscriber_people, :select => "DISTINCT users.*"
  # User requests to access private channels
  has_many :channel_requests, :dependent => :destroy

	has_many :video_graphs
	has_many :videos,	:dependent => :destroy, :order => 'created_at DESC'
	  has_many :comments, :through => :videos, :dependent => :destroy, :order => 'created_at DESC'
	  has_many :badges, :through => :videos, :dependent => :destroy, :order => 'created_at DESC'
	  has_many :tags, :through => :videos

  # These next associations are to ensure the associated objects are destroyed
  # when the parent object is destroyed
  has_many :comments, :dependent => :destroy
  has_many :blockings_by_them, :dependent => :destroy, 
                               :foreign_key => "requesting_user", 
                               :class_name => "Blocking"
  has_many :blockings_by_others, :dependent => :destroy, 
                                 :foreign_key => 'blocked_user', 
                                 :class_name => "Blocking"
  has_many :events_happening_to_them, :dependent => :destroy,
                                      :class_name => "UserEvent"
  has_many :events_created_by_them, :dependent => :destroy,
                                    :foreign_key => 'event_creator_id',
                                    :class_name => "UserEvent"
  
  has_many :people_they_are_blocking, :through => :blockings_by_them, :source => :blocked_people
  
  has_one :setting, :dependent => :destroy
    delegate :hide_getting_started, :send_email_for_new_badges, 
             :send_email_for_new_comments, :send_email_for_replies_to_a_prior_comment, 
             :send_email_for_new_subscriber, :send_email_for_featured_video,
             :send_email_for_private_channel_request, :send_email_for_encoding_completion,
             :to => :setting
  
  has_one :invitation_link, :dependent => :destroy
    delegate :invitation_limit, :to => :invitation_link
  
  has_many :social_networks, :dependent => :destroy
  
  # Use the :username instead of :id
  def to_param
    username
  end
  
  #######################
  # Notification Helper #
  #######################
  
  # Returns all notifications for a user (except video plays)
  def notifications_to_show_user
    notifications ||= UserEvent.where('user_id = ? AND error_during_render = ? AND event_type != ?', self.id, false, UserEvent.event_type_value(:video_play))
  end
  # Returns how many "unseen" latest activity events the user has
  def notifications_count
    notifications_count ||= self.notifications_to_show_user.where(:seen_by_user => false).count
  end
  
  #################
  # Video Helpers #
  #################
  
  # Returns all videos that have been featured by a given user
  def featured_videos
    Video.joins(:video_graph).where(:video_graphs => { :status => VideoGraph.get_status_number(:ready) }).where(:channel_id => self.channels.where(:featured => true).collect(&:id)).order('featured_at DESC')
  end
  # Returns videos from only the public channels for a given user
  def public_videos
    Video.joins(:video_graph).where(:video_graphs => { :status => VideoGraph.get_status_number(:ready) }).where(:channel_id => self.channels.where(:private => false).collect(&:id))
  end
  # Returns videos from ALL public AND private channels for a given user
  def all_videos
    Video.joins(:video_graph).where(:video_graphs => { :status => Video.statuses_to_show_to_current_user }).where(:channel_id => self.channels.collect(&:id))
  end
  # Returns videos from the public AND private channels the user is subscribed to
  def all_videos_for_subscriptions
    Video.joins(:video_graph).where(:video_graphs => { :status => VideoGraph.get_status_number(:ready) }).where(:channel_id => self.channel_subscriptions.collect(&:id))
  end
  
  ###################
  # Channel Helpers #
  ###################
  
  # Returns the featured channel for a given user
  def featured_channel
    self.channels.where(:featured => true).first
  end
  
  ##################
  ## User Helpers ##
  ##################
  
  # Returns a random set of users for the Find People page
  def self.show_random_people
    where('image IS NOT NULL').limit(100).order("RANDOM()")
  end
  
  ######################
  ## Sphinx Indexing  ##
  ## (only on heroku) ##
  ######################
  
  if Rails.env.production? || Rails.env.staging?
    define_index do
      indexes :name, :sortable => true
      indexes email
      
      has :id, created_at, updated_at
      
      set_property :delta => FlyingSphinx::DelayedDelta
    end
  end

  
  ####################
  ## Social Sign Up ##
  ####################
  
  # Associates a created user with the social attributes after sign up
  def associate_with_social_account(social_params, social_image_cookie, social_bio_cookie)
    if social_params["provider"].blank? || social_params["uid"].blank?
      Airbrake.notify(:error_class => "Logged Error", :error_message => "SOCIAL CREDENTIALS: The social credentials for #{self.id} did not get passed in from the sign up form.  This is what we received: Provider = #{social_params["provider"]} ; UID = #{social_params["uid"]}") if Rails.env.production?
    else
      # create a new social network record for storing their auth data in
      new_network ||= self.social_networks.new(:provider => social_params["provider"].strip.downcase, :uid => social_params["uid"].strip.downcase, :token => social_params["oauth_token"], :token_secret => social_params["oauth_token_secret"])
      if !new_network.save
        Airbrake.notify(:error_class => "Logged Error", :error_message => "SOCIAL CREDENTIALS: Error creating social credentials for #{self.id} with these params: Provider = #{social_params["provider"]} ; UID = #{social_params["uid"]}") if Rails.env.production?
      end
    end
                          
    # upload their image
    begin
      self.set_new_user_image(nil, social_image_cookie, false, true)
    rescue
      Airbrake.notify(:error_class => "Logged Error", :error_message => "PROFILE IMAGE: Error SAVING image from a social signup for #{self.email}.  The image was #{social_image_cookie}") if Rails.env.production?
    end
    
    # set their bio 
    self.profile.update_attribute('bio', truncate(social_bio_cookie, :length => 140, :omission => '...')) 
  end
  
  class << self
    # Returns a new user instance with attributes already pre-filled from social params
    def create_via_fb_or_twitter(auth_hash) 
      user = User.new
      
      begin
        user.username = auth_hash["user_info"]["nickname"].first(30) rescue nil
        user.name = auth_hash["user_info"]["name"].first(25) rescue nil
    
        case auth_hash["provider"]
        when "facebook"
          user.email = auth_hash["user_info"]["email"] rescue nil
          user.birthday = Date.strptime(auth_hash["extra"]["user_hash"]["birthday"], '%m/%d/%Y') rescue nil
          user.location = auth_hash["extra"]["user_hash"]["location"]["name"].first(20) rescue nil
          user.gender = auth_hash["extra"]["user_hash"]["gender"].capitalize rescue nil
        when "twitter"
          user.location = auth_hash["user_info"]["location"].first(20) rescue nil
        end 
      rescue Exception => e
        Airbrake.notify(:error_class => "Logged Error", :error_message => "SOCIAL SIGNUP: Just rescued an error during a social sign up.  Error was: #{e.inspect}") if Rails.env.production?
        return user
      end
      
      return user
    end
  end
  
  
  #################
  ## User Images ##
  #################
  
  # Retrieves the image location for a user banner image chosen from the Brevidy gallery
  def get_banner_image_url(banner_image_id)
    banner_image = BannerImage.where(:id => banner_image_id, :active => true).first
    if banner_image
      return "#{Brevidy::Application::S3_BASE_URL}/#{banner_image.path}/#{banner_image.filename}"
    else
      # The banner image is either inactive or could not be found so return the default one
      return "#{Brevidy::Application::S3_BASE_URL}/#{BannerImage.find_by_filename('banner-1.jpg').path}/#{BannerImage.find_by_filename('banner-1.jpg').filename}"
    end
  end
  
  # Task for processing and setting the new user images (profile or banner)
  def set_new_user_image(old_image, new_temp_image, banner_image, image_from_social_signup = false)
    # word of caution: if you try to remove the old image prior to setting
    # a new image, it will mysteriously not update the user with the new image
    # so instead just delete the old image as a delayed job

    #
    # IMPORTANT: do not put a leading / on the path
    # since we use the path to also clean up after ourselves
    #
    s3_path = "#{Brevidy::Application::S3_IMAGES_RELATIVE_PATH}/#{self.id}/"
    
    new_image_s3_url = image_from_social_signup ? new_temp_image : "#{Brevidy::Application::S3_BASE_URL}/#{s3_path}#{new_temp_image}"
    
    begin
      if banner_image
        self.remote_banner_image_url = new_image_s3_url
      else
        self.remote_image_url = new_image_s3_url
      end
      
      # tell the browser (which is polling) that we are through
      self.image_status = 'success'
      
      if self.save
        # reset banner_image_id if necessary so we know to use the new banner image they just uploaded
        self.update_attribute(:banner_image_id, 0) if banner_image
        
        # delete the old images as a delayed job
        clean_up_after_new_user_image(s3_path, old_image, new_temp_image)
      else
        self.update_attribute(:image_status, 'error')
        Airbrake.notify(:error_class => "Logged Error", :error_message => "USER IMAGE: Error SAVING (banner? #{banner_image}) image for #{self.email}") if Rails.env.production?
      end
      
    rescue Exception => e
      # tell the browser (which is polling) that we had an error
      self.update_attribute(:image_status, 'error')
      
      Airbrake.notify(:error_class => "Logged Error", :error_message => "USER IMAGE: Error SAVING (banner? #{banner_image}) image for #{self.email}.  The exception thrown was #{e}") if Rails.env.production?
    end
  end
  
  # Removes old user images from S3 via a delayed job
  def clean_up_after_new_user_image(s3_path, old_image, new_temp_image)
    f = Brevidy::Fog::S3::File.new
    f.delete(s3_path, new_temp_image) unless new_temp_image.blank?
    unless old_image.blank?
      f.delete(s3_path, old_image)
      f.delete(s3_path, 'small_profile_' + old_image)
      f.delete(s3_path, 'medium_profile_' + old_image)
      f.delete(s3_path, 'large_profile_' + old_image)
    end
  end
  handle_asynchronously :clean_up_after_new_user_image, :priority => 50
  
  
  ###################
  ## Subscriptions ##
  ################### 
  
  # Determines if a user is subscribed to a specific channel
  def is_subscribed_to?(channel)
    Subscription.where(:subscriber_id => self.id, :channel_id => channel.id).exists?
  end 
  
  
  ##############
  ## Blocking ##
  ############## 
  
  # Blocks a given user 
  def block!(user)
    User.transaction do
      subscriptions = Subscription.where(:subscriber_id => user.id, :publisher_id => self.id)
      subscriptions.destroy_all
      
      new_blocking = Blocking.new
      new_blocking.requesting_user = self.id
      new_blocking.blocked_user = user.id
      new_blocking.save!
    end
  end
  
  
	###################
  ## Count Helpers ##
  ###################
  
  # Returns how many videos the user has with a :ready state
  def videos_count
    videos.joins(:video_graph).where(:video_graphs => { :status => VideoGraph.get_status_number(:ready) }).count
  end
  
  # Returns how many unique people the user is subscribed to
  def subscriptions_count
    subscriptions.count
  end
  
  # Returns how many unique subscribers the person has
  def subscribers_count
    subscribers_as_people.uniq.count
  end

  # Returns how many badges the user has
  def badges_count
    badges.count
  end
  
  # Returns how many channels the user has
  def channels_count
    channels.count
  end
  
  # returns how many badges and of what type a user has
  def badges_count_for_type(badge_type)
	  self.badges.where(:badge_type => badge_type).count
  end
  
  
  ####################
  ## Authentication ##
  ####################
	
  class << self    
    def authenticate(email, submitted_password)
      user = find_by_email(email)
      (user && user.has_password?(submitted_password)) ? user : nil
    end
  
    def authenticate_with_salt(id, cookie_salt)
      user = find_by_id(id)
      (user && user.salt == cookie_salt) ? user : nil
    end
    
    # Setter for password encryption flag
    def should_encrypt_password=(flag)
      @encrypt_password_flag = flag
    end
  
    # Getter for password encryption flag
    def should_encrypt_password
      @encrypt_password_flag || false
    end
  end
  
  def has_password?(submitted_password)
    password == encrypt(submitted_password)
  end
  

  #################
  ## Validations ##
  #################
  
  # Returns whether or not the given username is acceptable
  class << self
    def verify_username_is_acceptable(username)
      return false if Rails.application.routes.routes.map(&:path).join("\n").scan(/\s\/(\w+)/).flatten.compact.uniq.include?(username)
      return false if RestrictedUsername.where(:username => username, :inclusive => false).exists?
      inclusive_restrictions ||= RestrictedUsername.where(:inclusive => true)
      (return false if username =~ /#{inclusive_restrictions.collect(&:username).join('|')}/i) unless inclusive_restrictions.blank?

      # if we got here, the username is okay
      return true
    end
  end
  
  # Cleans up the user params prior to validation
  def prepare_params_for_validation
    self.username = username.downcase.strip unless username.blank?
    self.name = name.strip unless name.blank?
    self.email = email.downcase.strip unless email.blank?
    self.password = password.strip unless password.blank?
  end
    
  private
    ########################
    ## Custom Validations ##
    ########################
    
    # Verifies the email address given has not been banned
    def email_address_has_not_been_banned
      errors.add(:email, "^That e-mail address has been banned") if BannedUser.where(:email => email).exists?
    end
    
    # Ensures that the user can only change their username once a month
    def username_changed_more_than_one_month_ago
      errors.add(:username, "^You cannot change your username more than once a month") if self.username_changed? && self.username_changed_at > 1.month.ago
    end
    
    # Ensures that the username given is allowable
    def username_is_acceptable
      errors.add(:username, "^That username is unacceptable") unless User.verify_username_is_acceptable(self.username)
    end
  
    ################
    ## User Setup ##
    ################
    
    # after_create callback to create the default username_updated_at datetime
    def create_username_changed_timestamp
      self.update_attribute(:username_changed_at, 2.months.ago)
    end

    # after_create callback to create the default channels for each user
    def create_default_channels
      private_chan = Channel.new
      private_chan.user_id = self.id
      private_chan.title = "Private Videos"
      private_chan.private = true
      private_chan.save
      
      public_chan = Channel.new
      public_chan.user_id = self.id
      public_chan.title = "Public Videos"
      public_chan.save
      
      featured_chan = Channel.new
      featured_chan.user_id = self.id
      featured_chan.title = "Featured Videos"
      featured_chan.featured = true
      featured_chan.save
    end

    # after_create callback to create a new profile associated with the user
    def create_profile
      new_profile = Profile.new
      new_profile.user_id = self.id
      new_profile.save!
    end
    
    # after_create callback to create default settings for the user
    def create_default_settings
      setting = Setting.new
      setting.user_id = self.id
      setting.save!
    end
    
    # after_create callback to create an invitation link for the user to give out
    def create_invitation_link
      new_invitation_link = InvitationLink.new
      new_invitation_link.user_id = self.id
      new_invitation_link.invitation_limit = 100
      new_invitation_link.save!
    end
    
    # after_create callback to subscribe the user to the default brevidy channels
    def subscribe_to_default_channels
      #User.find_by_username("brevidy").channels.where(:recommended => true).each { |c| c.subscribe!(self) } unless Rails.env.test?
    end
    
    #####################
    ## Password / Salt ##
    #####################
    
    def encrypt_password
      self.salt = make_salt if new_record?
      self.password = encrypt(password) if new_record? || User.should_encrypt_password
    end

    def encrypt(string)
      secure_hash("#{salt}--#{string}")
    end

    def make_salt
      secure_hash("#{Time.now.utc}--#{password}")
    end

    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end 

end









# == Schema Information
#
# Table name: users
#
#  id                  :integer         not null, primary key
#  email               :string(255)
#  password            :string(255)
#  salt                :string(255)
#  name                :string(255)
#  image               :string(255)
#  birthday            :date
#  gender              :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  location            :string(255)
#  reset_token         :string(255)
#  pw_reset_timestamp  :datetime
#  image_status        :string(255)
#  is_deactivated      :boolean         default(FALSE)
#  delta               :boolean         default(TRUE), not null
#  username            :string(255)
#  banner_image        :string(255)
#  banner_image_id     :integer         default(1)
#  username_changed_at :datetime
#  background_image_id :integer         default(0)
#


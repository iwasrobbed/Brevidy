require 'digest'

class Video < ActiveRecord::Base
  # custom module used for cleaning S3 after videos are deleted
  include Brevidy::Fog
  # used for getting information from YouTube and Vimeo links
  include RemoteVideoLinks
  # needed for truncate method
  include ActionView::Helpers::TextHelper

  # Lifecycle actions
  after_create :generate_public_token!, :touch_channel!
  before_validation :set_featured_at, :on => :create
  before_validation :trim_newlines_from_fields
  before_destroy :clean_up_if_necessary
  
  # whitelist to define which attributes can be mass-assigned
  attr_accessible :title, :description, :selected_thumbnail, :send_to_facebook, :send_to_twitter

  # validates these attribute conditions are met
  validates :user_id, :featured_at, :video_graph_id, :channel_id, :presence => true
  validates :selected_thumbnail,     :inclusion => 0..3
  validates :title,                  :presence => true,
                                     :length => { :maximum => 75 } 
  validates :description,            :length => { :maximum => 1000 } 
  
  # Active Record relationships
  belongs_to :user
  belongs_to :video_graph
  belongs_to :channel
  
  # UNCOMMENT AFTER MIGRATION
  delegate :thumbnail_path, :path, :base_filename, :encoding_type, :thumbnail_type, 
           :status, :zencoder_job_id, :remote_host, :remote_video_id, :remote_thumbnail, :to => :video_graph
	
	has_many :comments, :dependent => :destroy, :order => 'created_at ASC'
	has_many :badges, :dependent => :destroy, :order => 'created_at DESC'

  has_many :taggings, :dependent => :destroy
  has_many :tags, :through => :taggings

  
  ###############
  ## Constants ##
  ###############    
    
    # Video Player Constants
    PLAYER_WIDTH          = 786
    PLAYER_HEIGHT         = 480
    PUBLIC_PLAYER_WIDTH   = 786
    PUBLIC_PLAYER_HEIGHT  = 480


  ######################
  ## Sphinx Indexing  ##
  ## (only on heroku) ##
  ######################
  
  if Rails.env.production? || Rails.env.staging?
    define_index do
      indexes :title
      indexes :description
      indexes user(:name), :as => :posted_by
      indexes tags(:content), :as => :tags
      indexes video_graph(:status), :as => :status
      indexes channel(:private), :as => :channel_is_private
      
      has user_id, created_at
      
      set_property :delta => FlyingSphinx::DelayedDelta
    end
  end
  
  ################
  ## SEO Params ##
  ################
  
  # Creates an SEO friendly slug in the URL
  # i.e. http://brevidy.com/rob/videos/3-some-title-goes-here
  def to_param
    "#{id}-#{title.parameterize}"
  end
  
  ####################
  ## Update Helpers ##
  ####################
  
  # Overrides update attributes to update the channel information for a given video
  def update_attributes(attributes)
    video_owner = User.find_by_id(self.user_id)
    channel_id = attributes[:channel_id]
    
    if channel_id == "add_to_new_channel"
      new_channel ||= video_owner.channels.new(:title => attributes[:channel_name])
      new_channel.private = !attributes[:channel_is_private].blank?
      if new_channel.save
        channel_id = new_channel.id
      else
        self.errors.add(:channel_id, "^#{new_channel.errors.full_messages.to_sentence}")
        return false
      end
    end
    
    if video_owner.channels.where(:id => channel_id.to_i).exists?
      self.channel_id = channel_id
    else
      self.errors.add(:channel_id, "^The channel you selected was invalid.  Please select one of your channels.")
      return false
    end
    
    # Remove the unnecessary params
    attributes.delete("channel_id")
    attributes.delete("channel_name")
    attributes.delete("channel_is_private")
    
    super(attributes)
  end
  
  
  ######################
  ## Creation Helpers ##
  ######################
  
  class << self
    
    # Adds an existing video to a channel (i.e. reshares it)
    def add_video_to_channel!(current_user, video_id, channel_id, channel_name, is_private)
      new_video = current_user.videos.new
      
      # Do a quick security check to see if the current user can access
      # the video they are attempting to share
      video_to_share = Video.find_by_id(video_id)
      if video_to_share
        owning_channel = video_to_share.channel
        unless owning_channel.is_accessible_by(current_user)
          new_video.errors.add(:id, "^You do not have permission to share this video.")
          Airbrake.notify(:error_class => "Logged Error", :error_message => "ADD TO CHANNEL: User ##{current_user.id} tried sharing a video (#{video_to_share.id}) that they did not have access to.") if Rails.env.production?
          return new_video
        end
      else
        new_video.errors.add(:id, "^This video either could not be found or it might have been removed by the owner.")
        return new_video
      end
      
      # Check if video is in a private channel and the user doesn't own it
      # If so, don't let them share it
      if video_to_share.channel.private? && (video_to_share.channel.user_id != current_user.id)
        new_video.errors.add(:id, "^This video is in a private channel so it cannot be shared.")
        return new_video
      end
      
      # Create a new channel if necessary
      if channel_id == "add_to_new_channel"
        new_channel ||= current_user.channels.new(:title => channel_name)
        new_channel.private = !is_private.blank?
        if new_channel.save
          channel_id = new_channel.id
        else
          new_video.errors.add(:channel_id, "^#{new_channel.errors.full_messages.to_sentence}")
          return new_video
        end
      end
      
      # Find the channel and add the new video to it
      if current_user.channels.where(:id => channel_id.to_i).exists?
        # Set the video graph ID and save it
        new_video.title = video_to_share.title
        new_video.description = video_to_share.description
        new_video.video_graph_id = video_to_share.video_graph_id
        new_video.channel_id = channel_id
        new_video.save
      else
        # User tried to add the video to a channel that wasn't theirs or had issues
        new_video.errors.add(:channel_id, "^The channel you selected was invalid.  Please select one of your channels.")
        Airbrake.notify(:error_class => "Logged Error", :error_message => "SHARE A LINK: User ##{current_user.id} tried sharing a video into an invalid channel (##{channel_id})") if Rails.env.production?
      end
        
      return new_video
    end
    
    # Creates a new video from a remote (YouTube/Vimeo) link and shares it to a channel
    def create_shared_video!(current_user, remote_link, channel_id, channel_name, is_private)
      new_video = current_user.videos.new
        
      # Poll the video information
      remote_link_params ||= RemoteVideoLinks.get_video_information_from_link(remote_link)
    
      # Get the necessary params from the remote link
      remote_video_id = remote_link_params[0]
      remote_host = remote_link_params[1]
      remote_video_title = remote_link_params[2]
      remote_video_description = remote_link_params[3]
      remote_video_thumbnail = remote_link_params[4]
    
      # Check if any of the remote params came in bad
      if remote_video_id.blank? || remote_host.blank? || remote_video_thumbnail.blank?
        new_video.errors.add(:id, "^Error getting the video information.  Please verify the link is correct.")
      else
        # Create a new channel if necessary
        if channel_id == "add_to_new_channel"
          new_channel ||= current_user.channels.new(:title => channel_name)
          new_channel.private = !is_private.blank?
          if new_channel.save
            channel_id = new_channel.id
          else
            new_video.errors.add(:channel_id, "^#{new_channel.errors.full_messages.to_sentence}")
            return new_video
          end
        end
        
        # Find the channel and add the new video to it
        if current_user.channels.where(:id => channel_id.to_i).exists?
          # Find or create the video graph object
          video_graph ||= VideoGraph.where(:remote_host => remote_host, :remote_video_id => remote_video_id, :deleted => false).first
          if video_graph.blank?
            video_graph = current_user.video_graphs.create
            video_graph.upload_remote_thumbnail(remote_video_thumbnail)
            video_graph.set_status(VideoGraph::READY)
            video_graph.remote_host = remote_host.downcase.strip
            video_graph.remote_video_id = remote_video_id.strip
            video_graph.save
          end
          # Set the video graph ID and save it
          remote_video_title.blank? ? new_video.title = "Untitled" : new_video.title = remote_video_title
          new_video.description = remote_video_description
          new_video.video_graph_id = video_graph.id
          new_video.channel_id = channel_id
          new_video.save
        else
          # User tried to add the video to a channel that wasn't theirs or had issues
          new_video.errors.add(:channel_id, "^The channel you selected was invalid.  Please select one of your channels.")
          Airbrake.notify(:error_class => "Logged Error", :error_message => "SHARE A LINK: User ##{current_user.id} tried sharing a video into an invalid channel (##{channel_id})") if Rails.env.production?
        end
      end
      
      return new_video
    end 
    
  end
  
  
  ######################
  ## Standard Helpers ##
  ######################
  
  class << self
    # Returns an array of states viewable by the video owner
    def statuses_to_show_to_current_user
      return [ VideoGraph.get_status_number(:submitting), VideoGraph.get_status_number(:submitting_error),
               VideoGraph.get_status_number(:transcoding), VideoGraph.get_status_number(:transcoding_error),
               VideoGraph.get_status_number(:ready) ]
    end
    
    # Returns all available flag types
    def get_all_flags
      Flag.all
    end
  
  end
  
  # Check for video lifecycle status
  def is_status?(status)
    return case status
      when :uploading
        # Video is uploading to S3
        self.status == VideoGraph.get_status_number(:uploading)
      when :uploading_error
        # There was an error in video being uploaded to S3
        self.status == VideoGraph.get_status_number(:uploading_error)
      when :submitting
        # Video is to be sent to to Zen
        self.status == VideoGraph.get_status_number(:submitting)
      when :submitting_error
        # The were errors when sending the video to Zen
        self.status == VideoGraph.get_status_number(:submitting_error)
      when :transcoding
        # Video is being encoded by Zen
        self.status == VideoGraph.get_status_number(:transcoding)
      when :transcoding_error
        # There were errors when encoding the video
        self.status == VideoGraph.get_status_number(:transcoding_error)
      when :ready
        # Video is ready for display
        self.status == VideoGraph.get_status_number(:ready)
      when :fatal_error
        # Video cannot be encoded
        self.status == VideoGraph.get_status_number(:fatal_error)
      when :deleting
        # Video record and associated files marked for deletion
        self.status == VideoGraph.get_status_number(:deleting)
      when :deleting_error
        # Video record could not be deleted
        self.status == VideoGraph.get_status_number(:deleting_error)
      else
        false
    end
  end
  
  
  ####################
  ## Social Helpers ##
  ####################
  
  # Posts the video to facebook or twitter after it's ready
  def send_to_facebook_or_twitter(social_network, social_settings)
    token = social_settings.token
    
    begin
      case social_network
        when "facebook"
          graph = Koala::Facebook::API.new(token)
          graph.put_object("me", "feed", :message => "", 
                                         :picture => "#{self.get_thumbnail_url(self.selected_thumbnail)}", 
                                         :link => "#{Rails.application.routes.url_helpers.public_video_url(:public_token => self.public_token, :host => 'brevidy.heroku.com')}", 
                                         :name => "#{self.title unless self.title.blank?}", 
                                         :caption => "brevidy.com", 
                                         :description => "#{self.description}")
        when "twitter"
          token_secret = social_settings.token_secret
          Twitter.consumer_key = Brevidy::Application::TWITTER_CONSUMER_KEY
          Twitter.consumer_secret = Brevidy::Application::TWITTER_CONSUMER_SECRET
          Twitter.oauth_token = token
          Twitter.oauth_token_secret = token_secret
          description = truncate(self.description, :length => 70, :omission => '...')
          tweet = "Check out this video! #{description} #{Rails.application.routes.url_helpers.public_video_url(:public_token => self.public_token, :host => 'brevidy.heroku.com')} (via @brevidy)"
          Twitter.update(tweet)
      end
    
    rescue Exception => e
      # TODO: need to add error catch if they deauthorize us 
      # so we clear out their social credentials
      
      Airbrake.notify(:error_class => "Logged Error", :error_message => "POST TO SOCIAL NETWORK: Error posting video ID #{self.id} to #{social_network} ... error was: #{e}") if Rails.env.production?
    end
  end
  handle_asynchronously :send_to_facebook_or_twitter, :priority => 20


  ###################
  ## Badge Helpers ##
  ###################
  
  # Badges a video
  def badge_it(badge_from, badge_type)
    new_badge = self.badges.new(:badge_type => badge_type)
    
    if self.badges.where(:badge_from => badge_from.id, :badge_type => badge_type).first
      new_badge.errors.add(:badge_from, "^You have already badged this video using the #{Icon.find(badge_type).name} badge")
    else
      new_badge.badge_from = badge_from.id
      if new_badge.save      
        video_owner ||= User.find_by_id(self.user_id)
        # Send an e-mail and add an activity feed item unless the person badged their own 
        # video or their notification settings say not to           
        unless new_badge.badge_from == video_owner.id
         # Send e-mail
         UserMailer.delay(:priority => 40).new_badge(new_badge) if video_owner.send_email_for_new_badges
         # Activity feed item
         UserEvent.delay(:priority => 40).create(:event_type => UserEvent.event_type_value(:badge), 
                                                 :event_object_id => new_badge.id,
                                                 :user_id => video_owner.id,
                                                 :event_creator_id => badge_from.id)
        end
      end
    end
    
    return new_badge
  end
  
  # Returns whether or not a user has badged a video using a certain badge type
  def has_been_badged_with?(badge, user)
    badges.where(:badge_from => user, :badge_type => badge).first
  end
  
  # Returns an array of unique badge types and associated counts for a given video
  def unique_badge_types_and_counts
    unique_badges = []
    all_badge_types = []

    self.badges.group_by(&:badge_type).each do |badge_type, array_of_badges| 
      # put it into an array that we can use
      unique_badges << [ Icon.badges.where('id = ?', badge_type).first, array_of_badges.size ]
      all_badge_types << badge_type
    end
    return {:badge_sets => unique_badges.sort_by{|bdgs| bdgs[1]}.reverse, :all_badge_types => all_badge_types }
  end
  
  # Returns the count for a particular badge type on specified video
  def badges_count_for_type(badge_type)
    self.badges.where(:badge_type => badge_type).count
  end  


  #################
  ## Tag Helpers ##
  #################
  
  # Creates tags and/or a tagging relationship for a video
  def create_taggings(video_tag_string)
    # separate each tag by commas
    video_tags = video_tag_string.split(",") rescue nil
    unless video_tags.blank?
      video_tags.each do |video_tag|
        tag = Tag.find_or_create_by_content(video_tag.downcase.strip)
        self.taggings.find_or_create_by_tag_id(tag.id)
      end
    end
  end


  #################
  ## URL Helpers ##
  #################

  # Returns the thumbnail url for a given thumbnail number
  def get_thumbnail_url(thumbnail_number)
    thumbnail_url = "#{Brevidy::Application::S3_BASE_URL}/#{self.thumbnail_path}/#{self.thumbnail_type}_#{self.base_filename}_000#{thumbnail_number}.png"
    if self.remote_video_id.blank?
      # show the standard thumbnail
      return thumbnail_url
    else
      if self.remote_thumbnail.blank?
        # remote video thumbnail is still processing so show the
        # processing thumbnail for now
        return "#{Brevidy::Application::S3_BASE_URL}/images/shared_processing.png"
      else
        # remote video thumbnail is ready so show it
        return thumbnail_url
      end
    end
  end
  
  
  #################
  ## Secure URLs ##
  #################
  
  # Generates a time-sensitive, secure URL to a private video object on Amazon S3
  # Output looks something like:  
  # https://brevidytest.s3.amazonaws.com/videos/ok.m4v?AWSAccessKeyId=AKIAJPLELNYGJL5SYEEQ
  #         &Expires=1308755288&Signature=Amd6%2Fj4n4cFNOAAYz5MWIrb2Hgk%3D
  def generate_secure_s3_url
    # this was built using these instructions:
    # http://docs.amazonwebservices.com/AmazonS3/latest/dev/index.html?S3_QSAuth.html
    # http://aws.amazon.com/code/199?_encoding=UTF8&jiveRedirect=1

    s3_video_key      = self.path + "/#{self.encoding_type}_#{self.base_filename}.mp4" # i.e. uploads/videos/101/115/enc1_3064220bcff92be.mp4
    s3_base_url       = Brevidy::Application::S3_BASE_URL
    bucket            = Brevidy::Application::S3_BUCKET
    access_key_id     = Brevidy::Application::S3_ACCESS_KEY_ID
    secret_access_key = Brevidy::Application::S3_SECRET_ACCESS_KEY
    expiration_date   = 2.days.from_now.utc.to_i # epoch/UNIX time

    # this string needs to be formatted exactly as it is below or it will fail
    string_to_sign = "GET\n\n\n#{expiration_date}\n/#{bucket}/#{s3_video_key}".encode("UTF-8")

    # this must be CGI/URL encoded since a signature containing / or + characters will fail
    signature = CGI.escape( Base64.encode64(
                              OpenSSL::HMAC.digest(
                                OpenSSL::Digest::Digest.new('sha1'),
                                  secret_access_key, string_to_sign)).gsub("\n","") )

    # this needs to be all on one line or the video player poops it's pants
    return "#{s3_base_url}/#{s3_video_key}?AWSAccessKeyId=#{access_key_id}" + 
                                          "&Expires=#{expiration_date}" +
                                          "&Signature=#{signature}"
  end
  
  # Generates a time-sensitive, secure URL to a private video object on Amazon CloudFront
  # Output looks something like:  
  # http://d3rbgx27at2ch0.cloudfront.net/uploads/videos/1/1435/enc1_74692eda29c9c96.mp4?Expires=1328858020
  #        &Signature=ZImvIB262xVUF7JQ1nmK3aoNvT9IwUrlvwl7C6bUKZF52YeSoej2l1CgmQQMlj5vX6yZJQi7lomISHNgl7U0pvPPv6Eo2qY0oZ1BDXr4rHC5ATxuP2W2hmBSGX3BVw1gFEiuzh8qIXnz6pl-uPWhluXbHV3-mjTJ13FkSxlaqHs_
  #        &Key-Pair-Id=APKAIISGSMRX2LN43Q6A
  def generate_secure_cf_url
    cf_base_url = Brevidy::Application::CLOUDFRONT_BASE_URL
    video_key   = self.path + "/#{self.encoding_type}_#{self.base_filename}.mp4" # i.e. uploads/videos/101/115/enc1_3064220bcff92be.mp4
    
    # Pass in path to the private CloudFront key from AWS
    signer = AwsCfSigner.new("#{Rails.root}/config/amazon/pk-APKAIISGSMRX2LN43Q6A.pem")

    # Generate the signed URL
    url = signer.sign("#{cf_base_url}/#{video_key}", :ending => 14.days.from_now.utc.to_i)
  end
  
  
  ###################
  ## Embed Helpers ##
  ###################
  
  # Returns a video player object which handles Flash or HTML5 scenarios
  def get_html5_iframe_code(page_type = "individual")
    return RemoteVideoLinks.embed_html5_video_link(self.remote_host, self.remote_video_id, page_type, self.id).gsub("\n","")
  end
  
  
  #####################
  ## Sharing Helpers ##
  #####################
  
  # Shares a video via email 
  def share_via_email(current_user, recipient_emails, personal_message)
    share_errors = []
    blank_email_count = 0

    # strip out anything between quotes
    recipient_emails = Video.strip_quotes(recipient_emails)

    # split the emails by looking for a comma
    recipient_emails = recipient_emails.split(',')

    # Process each split entity
    recipient_emails.each do |recipient_email|
      # Strip off leading/trailing whitespace and make everything lower case
      recipient_email = recipient_email.strip.downcase

      # Checks for and ignores a blank email address between commas
      if !recipient_email.blank?
        recipient_email = Video.extract_email_address(recipient_email)
        if Video.this_is_a_valid_email?(recipient_email)
          UserMailer.delay(:priority => 40).share_video(current_user, self, recipient_email, personal_message)
        else
          share_errors << "#{recipient_email} is an invalid email address"
        end
      else
        # Keep track of all blank email addresses
        blank_email_count += 1
      end
    end

    # This checks for a situation where only blank email addresses were detected.
    if blank_email_count == recipient_emails.size
      share_errors << "You have not specified any email addresses to send this video to"
    end
    # return true unless there were errors and then return the errors
    return share_errors.flatten unless share_errors.empty?
  end
  
  
  private
    # Sets the featured_at time 
    def set_featured_at
      self.featured_at = Time.now
    end
  
    # Removes the associated video graph object if this is the last video object using it
    def clean_up_if_necessary
      unless Video.where('id != ? AND video_graph_id = ?', self.id, self.video_graph_id).exists?
        # mark the video graph for deletion (so no other video object uses it)
        vg = self.video_graph
        vg.deleted = true
        vg.save
        
        # cache the params to destroy
        cached_attributes ||= vg.get_attributes_needed_for_deleting
    
        # check if the video is in the middle of  transcoding 
        # to see if we're about to orphan some files on S3
        self.is_status?(VideoGraph::TRANSCODING) ? (orphaned = true) : (orphaned = false)
        
        # check if the S3 files were orphaned and use the appropriate clean up method
        if orphaned
          # clean up after ourselves after a long delay so we give
          # Zencoder ample time to place the orphaned files in the bucket
          VideoGraph.clean_up_on_S3_after_12_hours(cached_attributes)
        else
          # clean up after ourselves on S3 without a long delay
          VideoGraph.clean_up_on_S3(cached_attributes)
        end
      end
    end
    
    # If you don't do this, the length validation throws an error for whatever reason
    def trim_newlines_from_fields
      self.title = self.title.gsub(/\n|\r/, '') unless self.title.blank?
    end
    
    # Generates an 11 character public token for displaying videos without having to be authenticated
    def generate_public_token!
      loop do
        new_token = SecureRandom.base64(11).tr('+/=', 'xyz').first(11)
        break self.public_token = new_token unless Video.where(:public_token => new_token).exists?
      end
      self.save
    end
    
    # Updates the updated_at field for the associated channel to bring it to the top of the list
    def touch_channel!
      self.channel.update_attribute(:updated_at, Time.now) unless self.channel.blank?
    end
    
    # Email validations for sharing videos via email
    class << self
      # Validates an email address
      def this_is_a_valid_email?(email)
        email.match(User::EMAIL_REGEX)
      end

      # Strips anything with double quotes from the email address field
      # i.e. "Rob Phillips" <rob@brevidy.com> would return just <rob@brevidy.com>
      def strip_quotes(emails)
        return emails.gsub(/".*?"/, '')
      end

      # If email address is within <>, extract out address, or return original address if not between <>.
      def extract_email_address(email)
        # Check for <@> pattern and extract
        result = email[/<.+@.+>/]
        if result.nil?
          # If not found, return original email address for further validation
          return email
        else
          # If found return address minus the <> and leading/trailing spaces
          return result.gsub(/[<>]/,'<' => '', '>' => '').strip
        end
      end
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


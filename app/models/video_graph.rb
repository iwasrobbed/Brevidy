require 'timeout'

class VideoGraph < ActiveRecord::Base
  # whitelist to define which attributes can be mass-assigned
  attr_accessible :remote_thumbnail
  
  # handles uploading thumbnails
  # UNCOMMENT AFTER MIGRATION
  mount_uploader :remote_thumbnail, ThumbnailUploader
  
  # Lifecycle actions
  # UNCOMMENT AFTER MIGRATION
  before_validation :set_base_filename, :on => :create
  after_create :set_path!, :set_thumbnail_path!
  
  # Active Record relationships
  belongs_to :user
  has_many :videos, :dependent => :destroy
  has_many :video_errors
  
  # validates these attribute conditions are met                   
  validates :user_id, :base_filename, :encoding_type, :thumbnail_type, :status, :presence => true
  validates :remote_host,  :on => :create,
                           :inclusion => { :in => ["vimeo.com", "youtube.com", "youtu.be"],
                                           :message => "^We only allow YouTube or Vimeo videos at this time"},
                           :allow_blank => true,
                           :allow_nil => true
  ###############
  ## Constants ##
  ###############    
    
    # Status Constants
    CREATED           = :created # VideoGraph object waiting for upload to start
    UPLOADING         = :uploading # Video is uploading to S3
    UPLOADING_ERROR   = :uploading_error # There was an error in video being uploaded to S3
    SUBMITTING        = :submitting # Video is to be sent to to Zencoder
    SUBMITTING_ERROR  = :submitting_error # The were errors when sending the video to Zencoder
    TRANSCODING       = :transcoding # Video is being encoded by Zencoder
    TRANSCODING_ERROR = :transcoding_error # There were errors when encoding the video
    READY             = :ready # Video is ready for display
    FATAL_ERROR       = :fatal_error # Video cannot be encoded
    DELETING          = :deleting # Video record and associated files marked for deletion
    DELETING_ERROR    = :deleting_error # Video record could not be deleted
  
  ################
  ## S3 Helpers ##
  ################
  
  def upload_remote_thumbnail(remote_video_thumbnail)
    begin
      # download, process, and save the remote video thumbnail on S3
      self.remote_remote_thumbnail_url = remote_video_thumbnail
      self.save
      
    rescue
      # tell us about the error
      Airbrake.notify(:error_class => "Logged Error", :error_message => "SHARING LINK ERROR: There was an error uploading the thumbnail for Video ID: #{self.id} | Thumbnail: #{remote_video_thumbnail}") if Rails.env.production?
    end
  end
  # test real-time uploads of thumbnails
  # handle_asynchronously :upload_remote_thumbnail, :priority => 0
  
  
  ##################
  ## Meta Helpers ##
  ##################
  
  # Gets the user who originally uploaded this video so we properly attribute it
  def get_user_who_uploaded_this
    User.find_by_id(self.user_id) rescue nil
  end
  
  
  ##############
  ## Encoding ##
  ##############
  
  # Send a video to Zencoder for encoding. 
  def encode
    # Set up parameters for encoding
    user = User.find_by_id(self.user_id)
    video = Video.find_by_video_graph_id(self.id)
    base_path = "#{Brevidy::Application::S3_BASE_URL}/#{Brevidy::Application::S3_VIDEOS_RELATIVE_PATH}"
    input_file = "#{base_path}/#{user.id}/orig_#{self.base_filename}_#{user.id}"
    output_path = "#{base_path}/#{user.id}/#{self.id.to_s}/"
    enc_file_name = "#{self.encoding_type}_#{self.base_filename}.mp4"
    thumb_file_name = "#{self.thumbnail_type}_#{self.base_filename}"

    # Figure out callback information
    if Rails.env.production? || Rails.env.staging?
      ze_host = Rails.env.staging? ? "brevidystaging.heroku.com" : "brevidy.heroku.com"
      callback_url = Rails.application.routes.url_helpers.user_video_encoder_callback_url(user, video, :host => ze_host)

      # Set up how we want Zencoder to notify us after transcoding success/failure
      notifications = [{ :format => "json",
                         :url => callback_url }]
    else
      # We won't get a notification from Zencoder if we are in dev or test environments
      notifications = nil
    end

    # Submit job to Zencoder with a 30 second timeout.
    begin
      Timeout::timeout(30) {
        response = Zencoder::Job.create({:input => input_file,
                                  :pass_through => video.id,
                                  :outputs => [{
                                     :access_control => [
                                       { :permission => "READ",
                                         :grantee => "your_key_goes_here" },
                                       { :permission => "FULL_CONTROL",
                                         :grantee => "your_key_goes_here" }
                                     ],      
                                     :format => 'mp4',
                                     :audio_codec => 'aac',
                                     :video_codec => 'h264',
                                     :label => self.base_filename,
                                     :base_url => output_path,
                                     :filename => enc_file_name,
                                     :clip_length => 600,
                                     :width => 1264,
                                     :height => 711,
                                     :public => false,
                                     :thumbnails => [{
                                         :access_control => [
                                           { :permission => "READ",
                                             :grantee => "http://acs.amazonaws.com/groups/global/AllUsers" },
                                           { :permission => "FULL_CONTROL",
                                             :grantee => "your_key_goes_here" }
                                         ],  
                                         :label => "thumbs",
                                         :number => 4,
                                         :base_url => output_path,
                                         :height => 134,
                                         :width => 250,
                                         :aspect_mode => "pad",
                                         :prefix => thumb_file_name,
                                         :public => true,
                                         :rrs => true
                                      }],
                                     :notifications => notifications
                                  }]
                                });
                                            
        if response.code.to_i == 201
          # reset submitting error count
          self.submitting_error_count = 0
          # set the zencoder job id
          self.zencoder_job_id = response.body["id"].to_i
            
          if Rails.env.production? || Rails.env.staging?
            self.set_status(VideoGraph::TRANSCODING)
          else
            # Set to done because if we aren't on heroku then we can't get zencoder callbacks.
            self.set_status(VideoGraph::READY)
          end
        else
          # Store off error message and set the status to :submitting_error
          # so we retry the connection every minute until successful
          self.error_message = response.inspect.to_s
          self.set_status(VideoGraph::SUBMITTING_ERROR)
          # save the error for QA tracking and analytics
          self.video_errors.create(:user_id => user.id, :error_status => self.status, :error_message => self.error_message)
          # increment the submitting error count
          self.increment :submitting_error_count
          Airbrake.notify(:error_class => "Logged Error", :error_message => "ZENCODER CONNECTION ERROR: Zen response code was #{response.code}") if Rails.env.production?
        end
        
        # save the video state
        self.save
      } # end of timeout
      
    # Rescue any connection error. The Zencoder plugin 
    # abstracts these as Zencoder::HTTPError.
    rescue Timeout::Error, Zencoder::HTTPError
      # Set the status to :transfer_error so we retry the 
      # connection every minute until successful
      self.set_status(VideoGraph::SUBMITTING_ERROR)
      # save the error for QA tracking and analytics
      self.video_errors.create(:user_id => user.id, :error_status => self.status, :error_message => "Timeout::Error or Zencoder::HTTPError")
      # increment the submitting error count
      self.increment :submitting_error_count
      self.save
      Airbrake.notify(:error_class => "Logged Error", :error_message => "ZENCODER CONNECTION ERROR: Connection timed out or Zencoder returned an HTTPError") if Rails.env.production?
    end
  end
  
  # Handles what happens when we have an error with the transcoding process
  def handle_transcoding_error(errors_hash)
    self.error_message = errors_hash.to_s
    self.increment :transcoding_error_count
    
    if self.error_message.include?("TranscodingError") || self.error_message.include?("WorkerTimeoutError")
      self.set_status(VideoGraph::TRANSCODING_ERROR)
      if (self.transcoding_error_count >= 3 )
        Airbrake.notify(:error_class => "Logged Error", :error_message => "MULTIPLE TRANSCODING ERRORS: We should investigate. There were multiple transcoding errors for video graph ID: #{self.id}") if Rails.env.production?
      end
    else
      self.set_status(VideoGraph::FATAL_ERROR)
      Airbrake.notify(:error_class => "Logged Error", :error_message => "FATAL TRANSCODING ERROR: Zencoder said it was impossible to encode video graph ID: #{self.id}.") if Rails.env.production?
      # Send an e-mail to the user about it
      UserMailer.delay(:priority => 40).fatal_error_on_video(User.find_by_id(self.user_id))
    end
    # save the record
    self.save
    
    # save the error for QA tracking and analytics
    self.video_errors.create(:user_id => self.user_id, :error_status => self.status, :error_message => self.error_message)
  end
  
  
  ####################
  ## Status Helpers ##
  ####################

  # Setter for video lifecycle status
  def set_status(status)
    case status
      when :created
        # VideoGraph object waiting for upload to start
        self.status = VideoGraph.get_status_number(:created)
      when :uploading
        # Video is uploading to S3
        self.status = VideoGraph.get_status_number(:uploading)
      when :uploading_error
        # There was an error in video being uploaded to S3
        self.status = VideoGraph.get_status_number(:uploading_error)
      when :submitting
        # Video is to be sent to to Zen
        self.status = VideoGraph.get_status_number(:submitting)
      when :submitting_error
        # The were errors when sending the video to Zen
        self.status = VideoGraph.get_status_number(:submitting_error)
      when :transcoding
        # Video is being encoded by Zen
        self.status = VideoGraph.get_status_number(:transcoding)
      when :transcoding_error
        # There were errors when encoding the video
        self.status = VideoGraph.get_status_number(:transcoding_error)
      when :ready
        # Video is ready for display
        self.status = VideoGraph.get_status_number(:ready)
      when :fatal_error
        # Video cannot be encoded
        self.status = VideoGraph.get_status_number(:fatal_error)
      when :deleting
        # Video record and associated files marked for deletion
        self.status = VideoGraph.get_status_number(:deleting)
      when :deleting_error
        # Video record could not be deleted
        self.status = VideoGraph.get_status_number(:deleting_error)
    end
    return nil
  end
  
  # Returns a string for a video lifecycle status
  def translate_status
    return case self.status
      when 0
        "created"
      when 1
        "uploading"
      when 2
        "uploading_error"
      when 3
        "submitting"
      when 4
        "submitting_error"
      when 5
        "transcoding"
      when 6
        "transcoding_error"
      when 7
        "ready"
      when 8
        "fatal_error"
      when 9
        "deleting"
      when 10
        "deleting_error"
      else
        false
    end
  end
  
  class << self
    # Returns an integer for a video lifecycle status
    def get_status_number(status)
      return case status
        when :created
          0
        when :uploading
          1
        when :uploading_error
          2
        when :submitting
          3
        when :submitting_error
          4
        when :transcoding
          5
        when :transcoding_error
          6
        when :ready
          7
        when :fatal_error
          8
        when :deleting
          9
        when :deleting_error
          10
        else
          false
      end
    end
  
    #######################
    ## Video Job Helpers ##
    #######################

    # removes all video files and thumbnails on S3
    # you cannot do this in a before_destroy since delayed_job will
    # give you a deserialization error for acting on a destroyed object
    def clean_up_on_S3(cached_attributes)
      video_owner_id = cached_attributes[0]
      video_path = cached_attributes[1]
      base_filename = cached_attributes[2]
      encoding_type = cached_attributes[3]
      thumbnail_type = cached_attributes[4]
      
      f = Brevidy::Fog::S3::File.new
  
      unless base_filename.blank? || base_filename == "sample_populated"
        # delete the original video file
        original_video_path = "#{Brevidy::Application::S3_VIDEOS_RELATIVE_PATH}/#{video_owner_id}/"
        f.delete(original_video_path, "orig_#{base_filename}_#{video_owner_id}")
  
        # now delete the processed video and thumbnails
        # these paths require a trailing slash since the video path doesn't come with one
        f.delete("#{video_path}/", "#{encoding_type}_#{base_filename}.mp4")
        f.delete("#{video_path}/", "#{thumbnail_type}_#{base_filename}_0000.png")
        f.delete("#{video_path}/", "#{thumbnail_type}_#{base_filename}_0001.png")
        f.delete("#{video_path}/", "#{thumbnail_type}_#{base_filename}_0002.png")
        f.delete("#{video_path}/", "#{thumbnail_type}_#{base_filename}_0003.png")
        
        # Remove the video graph object
        vg = VideoGraph.find_by_base_filename(base_filename)
        vg.destroy unless vg.blank?
      end
    end
    handle_asynchronously :clean_up_on_S3, :priority => 50
    
    # Removes files from S3 that had their video objects deleted while the 
    # video was still transcoding on Zencoder.  This runs after 12 hours have passed
    # (i.e. Zencoder will still place the orphaned files on S3 after it's done)
    def clean_up_on_S3_after_12_hours(cached_attributes)
      # clean up after ourselves on S3
      VideoGraph.clean_up_on_S3(cached_attributes)
    end
    handle_asynchronously :clean_up_on_S3_after_12_hours, :priority => 50, :run_at => Proc.new { 12.hours.from_now }
    
    # Runs every minute to check for videos that are in the pending state
    # and attempts to re-run them again via delayed_job since cron jobs 
    # are only hourly on Heroku
    def run_pending_or_failed_video_encodings
      # Find all that had less than or equal to 3 submitting error responses from Zencoder
      submitting_error_videos = VideoGraph.where('status = ? AND submitting_error_count <= ?', VideoGraph.get_status_number(:submitting_error), 3)
      submitting_error_videos.each do |sev|
        sev.set_status(VideoGraph::SUBMITTING)
        sev.save
        sev.encode
      end
      
      # Find all that had failures from Zencoder and
      # only retry ones with TranscodingError or WorkerTimeoutError
      # https://app.zencoder.com/docs/guides/advanced-integration/retrying-failed-jobs
      failed_videos = VideoGraph.where("status = ? AND 
                        (error_message LIKE '%TranscodingError%' OR error_message LIKE '%WorkerTimeoutError%') AND
                        transcoding_error_count <= ?", VideoGraph.get_status_number(:transcoding_error), 3)
      failed_videos.each do |fv|
        fv.set_status(VideoGraph::SUBMITTING)
        fv.save
        fv.encode
      end
      
      # run again in 1 minute
      VideoGraph.run_pending_or_failed_video_encodings
    end
    handle_asynchronously :run_pending_or_failed_video_encodings, :priority => 50, :run_at => Proc.new { 1.minute.from_now }
  
    # Set uploading_error for any videos that have been in the 
    # uploading state for more than 7 days
    def check_videos_for_stale_uploading_states
      stale_videos = VideoGraph.where('created_at < ? AND status = ?',  7.days.ago, VideoGraph.get_status_number(:uploading))
      stale_videos.each do |sv|
        sv.set_status(VideoGraph::UPLOADING_ERROR)
        sv.save
      end
    end
    handle_asynchronously :check_videos_for_stale_uploading_states, :priority => 50
    
    # Removes all videos that are considered irreparable from the db and S3
    # since all quality assurance data about failures is stored in video_errors table
    def remove_irreparable_videos
      irreparable_statuses = [ VideoGraph.get_status_number(:uploading_error),
                               VideoGraph.get_status_number(:fatal_error) ]
      irreparable_videos = VideoGraph.where('status IN (?)', irreparable_statuses)
      irreparable_videos.each do |iv|
        cached_attributes ||= iv.get_attributes_needed_for_deleting
        if iv.destroy
          # clean up after ourselves on S3
          VideoGraph.clean_up_on_S3(cached_attributes)
        else
          # set video status to deleting error so admins can investigate
          iv.set_status(VideoGraph::DELETING_ERROR)
          iv.save
        end 
      end
    end
    handle_asynchronously :remove_irreparable_videos, :priority => 50
    
    # Attempts to resubmit videos with more than 3 submitting errors every hour via cron
    def resubmit_videos_with_submitting_errors
      submitting_error_videos = VideoGraph.where('status = ? AND submitting_error_count > ?', VideoGraph.get_status_number(:submitting_error), 3)
      submitting_error_videos.each do |sev|
        sev.set_status(VideoGraph::SUBMITTING)
        sev.save
        sev.encode
      end
    end
    handle_asynchronously :resubmit_videos_with_submitting_errors, :priority => 0
    
  end
  
  # Returns an array of attributes needed to remove videos from S3
  def get_attributes_needed_for_deleting
    # returns path, base_filename, encoding_type, and thumbnail_type
    return [ self.user_id, self.path, self.base_filename, self.encoding_type, self.thumbnail_type ]
  end
  
  private
  
    # Sets the base filename (20 character SHA2 hex) for a new VideoGraph object
    def set_base_filename
      loop do
        random_token = Digest::SHA2.hexdigest("#{Time.now.utc}--#{rand(99999)}").first(20)
        break self.base_filename = random_token unless VideoGraph.where(:base_filename => random_token).exists?
      end
    end
    
    # Sets the path for video based upon final expected path after encoding
    def set_path!
      self.path = "#{Brevidy::Application::S3_VIDEOS_RELATIVE_PATH}/#{self.user_id}/#{self.id}"
      self.save
    end

    # Sets the path for thumbnail of the video based upon final expected path after encoding
    def set_thumbnail_path!
      self.thumbnail_path = "#{Brevidy::Application::S3_VIDEOS_RELATIVE_PATH}/#{self.user_id}/#{self.id}"
      self.save
    end
  
end







# == Schema Information
#
# Table name: video_graphs
#
#  id                      :integer         not null, primary key
#  thumbnail_path          :string(255)
#  path                    :string(255)
#  callback_url            :string(255)
#  base_filename           :string(255)
#  encoding_type           :string(255)     default("enc1")
#  thumbnail_type          :string(255)     default("thumb1")
#  status                  :integer         default(0)
#  zencoder_job_id         :integer
#  remote_host             :string(255)
#  remote_video_id         :string(255)
#  remote_thumbnail        :string(255)
#  delta                   :boolean         default(TRUE), not null
#  created_at              :datetime
#  updated_at              :datetime
#  submitting_error_count  :integer         default(0)
#  transcoding_error_count :integer         default(0)
#  error_message           :text
#  user_id                 :integer
#  deleted                 :boolean         default(FALSE)
#


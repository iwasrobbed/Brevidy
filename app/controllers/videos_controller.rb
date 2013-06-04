class VideosController < ApplicationController
  include ApplicationHelper

  skip_before_filter :http_authenticate, :verify_authenticity_token, :only => [:encoder_callback]
  skip_before_filter :site_authenticate, :only => [:embed_code, :encoder_callback, :explore, :flag, :flag_video_dialog, :share_via_email, :show]
  before_filter :set_user, :except => [:explore]
  before_filter :verify_current_user_is_not_blocked, :only => [:add_to_channel, :add_to_channel_dialog, :flag, :flag_video_dialog]
  before_filter :set_video_based_on_user, :only => [:destroy, :edit, :embed_code, :flag, :flag_video_dialog, :share_via_email, :show]
  before_filter :verify_user_can_access_channel, :only => [:share_via_email, :show]
  before_filter :verify_user_can_access_channel_or_video, :only => [:embed_code]
  before_filter :verify_user_owns_video, :only => [:destroy, :edit]
  before_filter :set_featured_videos, :only => [:show]
  
  respond_to :js, :only => [:add_to_channel_dialog]
  
  # POST /:username/add_to_channel
  # Access control is handled in the "add_video_to_channel!" method
  def add_to_channel    
    new_shared_video ||= Video.add_video_to_channel!(current_user, 
                                                     params[:video_id],
                                                     params[:channel_id], 
                                                     params[:channel_name],
                                                     params[:channel_is_private])
  
    if new_shared_video.errors.any?
      render :json => { :error => get_errors_for_class(new_shared_video).to_sentence },
             :status => :unprocessable_entity
    else
      render :nothing => true, :status => :created
    end
  end
  
  # GET /:username/add_to_channel/dialog
  # Access control is handled within this method
  def add_to_channel_dialog
    @video ||= Video.where(:id => params[:video_id]).joins(:video_graph).where(:video_graphs => { :status => VideoGraph.get_status_number(:ready) }).first
    render :json => { :error => "That video could not be found." }, :status => :not_found and return if @video.blank?
  
    if @video.channel.private? && !current_user_owns?(@video)
      render :json => { :error => "This video is in a private channel so it cannot be shared." }, 
             :status => :unprocessable_entity
    else    
      @user ||= get_object_owner(@video)
      if user_can_access_channel         
        respond_with(@user, @video)
      else
        render :json => { :error => "You do not have permission to share this video." },
               :status => :unauthorized
      end
    end
  end
  
  # DELETE /:username/videos/:id
  def destroy  
    if @video.destroy
      render :nothing => true, :status => :ok
    else
      render :json => { :error => get_errors_for_class(@video).to_sentence }, 
             :status => :unprocessable_entity
    end
  end
  
  # GET /:username/videos/:id/edit
  def edit
    @browser_title ||= "Edit Video"
  end
  
  # GET /:username/videos/:video_id/embed_code
  def embed_code
    render :json => { :html => render_to_string( :partial => 'videos/embed_code.html',
                                                 :locals => { :video => @video } )  
                    },
           :status => :ok

    # Create an entry for a video being played
    UserEvent.create(:event_type => UserEvent.event_type_value(:video_play), 
                     :event_object_id => @video.id,
                     :user_id => @video.user_id,
                     :event_creator_id => current_user.blank? ? 0 : current_user.id)
  end
  
  # POST /:username/videos/:id/encoder_callback
  def encoder_callback    
    @video = @user.videos.find_by_id(params[:video_id])
    if @video
      # Check for expected JSON params in callback.
      if !(params[:output].blank? or params[:output][:state].blank?)
        job_state = params[:output][:state]

        # Check that video was in the expected state.
        if @video.is_status?(VideoGraph::TRANSCODING)

          if job_state.downcase == "finished"
            # Transcoding was successful
            vg = @video.video_graph
            vg.set_status(VideoGraph::READY)
            vg.save

            # set the created_at time to right now so it shows
            # at the top of the stream
            @video.created_at = Time.now
            @video.save
        
            # send the video to their social networks
            video_owner = User.find_by_id(@video.user_id)
            facebook_connected = SocialNetwork.find_by_user_id_and_provider(video_owner.id, "facebook") 
            twitter_connected = SocialNetwork.find_by_user_id_and_provider(video_owner.id, "twitter")
            @video.send_to_facebook_or_twitter("facebook", facebook_connected) if (@video.send_to_facebook? && facebook_connected)
            @video.send_to_facebook_or_twitter("twitter", twitter_connected) if (@video.send_to_twitter? && twitter_connected)
      
            UserMailer.delay.video_is_done_encoding(video_owner, @video) if video_owner.send_email_for_encoding_completion
          else
            # Transcoding had an error
            # Handle the transcoding error by either retrying
            # the job or treating it as a fatal error
            @video.video_graph.handle_transcoding_error(params)
          end

          render :text => "Video encoding status received.",
                 :status => :ok
        else
          # Don't modify the state, tell Zencoder we got this, and log an error so we can investigate
          render :text => "Error: Video in unexpected state.",
                 :status => :ok
          Airbrake.notify(:error_class => "Logged Error", :error_message => "ERROR: Callback received on file in incorrect state. Expected state: Transcoding. State: #{@video.status}") if Rails.env.production?
        end
      else
        # Don't modify the state and return a malformed request error to Zencoder
        render :text => "Error: Malformed callback.",
               :status => :bad_request
        Airbrake.notify(:error_class => "Logged Error", :error_message => "ERROR: Callback received with malformed parameters.  Params: #{params}") if Rails.env.production?
      end
    else
      render :text => "Error: Video not found (it might have been deleted).",
             :status => :not_found
    end
=begin
    # Sample success response from zencoder
    
    {"output"=>{"state"=>"finished", "url"=>"http://brevidytest.s3.amazonaws.com/uploads/videos/101/111/enc1_f64d1d9f26314cb.mp4", "label"=>"f64d1d9f26314cb", "id"=>5264824},
    "job"=>{"test"=>true, "state"=>"finished", "id"=>4955170},
    "action"=>"encoder_callback",
    "controller"=>"videos",
    "user_id"=>"101",
    "id"=>"111"}
=end
  end
  
  # GET /explore
  def explore
    # show the 4 latest featured videos
    #@latest_featured_videos = User.find_by_username("brevidy").featured_videos.limit(4)
    
    @latest_featured_videos = []
    
    # only show most recent public videos that have a :ready state
    @videos ||= Video.joins(:channel).where(:channels => { :private => false }).joins(:video_graph).where(:video_graphs => { :status => VideoGraph.get_status_number(:ready) }).
                      paginate(:page => params[:page], :per_page => 10, :order => 'created_at DESC')
  
    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end
  end
  
  # POST /:username/videos/:video_id/flag
  def flag
    flag_id = params[:flag_id]
    detailed_reason = params[:detailed_reason]

    if flag_id && Flag.where(:id => flag_id).exists?
      
      if signed_in?      
        # Check if the currently signed in user has already flagged this video for this reason
        if VideoFlag.where(:flagged_by => current_user.id, :video_id => @video.id, :flag_id => flag_id).exists?
          render :json => { :error => "You have already flagged this video for this reason.  Thank you for your patience while we look into the issue for you." }, 
                 :status => :unprocessable_entity and return
        end
      else
        # Check if a cookie exists that says they have already flagged this video for this reason
        unless session[:flagged_video].blank?
          if session[:flagged_video][:video_id] == @video.id && session[:flagged_video][:flag_id] == flag_id
            render :json => { :error => "You have already flagged this video for this reason.  Thank you for your patience while we look into the issue for you." }, 
                   :status => :unprocessable_entity and return
          end
        end
      end
      
      # Video has not been flagged by the current user or the signed out user, so let's flag it
      new_flagging = VideoFlag.new(:flag_id => flag_id, 
                                   :detailed_reason => detailed_reason)
      new_flagging.video_id = @video.id
      new_flagging.flagged_by = signed_in? ? current_user.id : nil                            
      if new_flagging.save
        render :nothing => true,
               :status => :created
      
        # Send an email to support@brevidy.com
        UserMailer.delay(:priority => 40).flagged_video(new_flagging, current_user)
        
        # Save a cookie about this event
        session[:flagged_video] = { :video_id => @video.id, :flag_id => flag_id }
      else
        render :json => { :error => get_errors_for_class(new_flagging).to_sentence }, 
               :status => :unprocessable_entity
        Airbrake.notify(:error_class => "Logged Error", :error_message => "FLAGGING: We were unable to flag a video for User (#{current_user.email unless current_user.blank?}), Video (#{video_id}), Flag Type (#{flag_id}), and Detailed Reason #{detailed_reason})") if Rails.env.production?
      end

    else
      render :json => { :error => "You must select one of the given options for why you want to flag the video!" }, 
           :status => :unprocessable_entity
    end
  end
  
  # GET /:username/videos/:video_id/flag_video_dialog
  def flag_video_dialog
    respond_to do |format|
      format.js # flag_video_dialog.js.haml
    end
  end

  # GET /:username/videos/new
  def new
    # Make sure we don't cache this page (since it would allow the user to overwrite previous videos)
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    
    @browser_title ||= "Upload a Video"
    
    # Create a temp video and video_graph object
    # and break some conventions along the way
    begin
      @new_video_graph_object ||= current_user.video_graphs.create
      @video ||= current_user.videos.new(:title => "Yayyy a new video!!!")
      @video.video_graph_id = @new_video_graph_object.id
      @video.channel_id = current_user.channels.first.id
      @video.save
    rescue
      Airbrake.notify(:error_class => "Logged Error", :error_message => "ERROR CREATING VIDEO UPLOAD OBJECTS: We could not create the new video and video_graph objects for this user: #{current_user.email}") if Rails.env.production?
      @error_creating_video_object = true
    end
  
    @facebook_connected = SocialNetwork.find_by_user_id_and_provider(current_user.id, "facebook") 
    @twitter_connected = SocialNetwork.find_by_user_id_and_provider(current_user.id, "twitter") 

    respond_to do |format|
      format.html # new.html.haml
    end
  end
  
  # POST /:username/share
  def share
    new_shared_video ||= Video.create_shared_video!(current_user, 
                                                    params[:shared_video_link], 
                                                    params[:channel_id], 
                                                    params[:channel_name],
                                                    params[:channel_is_private])
    
    if new_shared_video.errors.any?
      render :json => { :error => get_errors_for_class(new_shared_video).to_sentence },
             :status => :unprocessable_entity
    else
      redirect_to current_user
    end
  end
  
  # GET /:username/share_dialog
  def share_dialog
    respond_to do |format|
      format.js # share_dialog.js.haml
    end
  end
  
  # POST /:username/videos/:id/share_via_email
  def share_via_email
    if @video.channel.private? && !current_user_owns?(@video)
      render :json => { :error => "This video is in a private channel so it cannot be shared." }, 
             :status => :unprocessable_entity
    else
      if params[:recipient_email].blank?
        render :json => { :error => "You have not specified any email addresses to send this video to" }, 
               :status => :unprocessable_entity
      else
        shared_errors = @video.share_via_email(current_user, params[:recipient_email], params[:personal_message])
        if shared_errors.blank?
          render :json => { :message => "We have shared this video via email for you!" },
                 :status => :ok
        else
          render :json => { :error => shared_errors },
                 :status => :unprocessable_entity
        end
      end
    end
  end
  
  # GET /:username/videos/:id
  def show
    @browser_title ||= @user.name
     
    respond_to do |format|
      format.html
    end
  end

  # PUT /:username/videos/:video_id/successful_upload
  def successful_upload
    if params[:video_id].blank?
      Airbrake.notify(:error_class => "Logged Error", :error_message => "ERROR: Error SAVING new video info for #{current_user.email} during upload.  REASON: video_id was blank.") if Rails.env.production?
      render :json => { :error => "There was an error saving your new video.  We have been notified of this issue." },
             :status => :unprocessable_entity
    else
      new_video = current_user.videos.find_by_id(params[:video_id])
      # Check the video exists
      if new_video
        # send back response
        render :json => { :success_message => "Video uploaded! Go explore while we finish it up!",
                          :edit_video_path => edit_user_video_path(current_user, new_video) },
               :status => :accepted
        
        # Change the VideoGraph to a submitting state
        # Kick off the Zencoder encoding as a delayed job
        new_video_graph = new_video.video_graph
        new_video_graph.set_status(VideoGraph::SUBMITTING)
        new_video_graph.save
        new_video_graph.delay(:priority => 0).encode
      else
        Airbrake.notify(:error_class => "Logged Error", :error_message => "ERROR: Error SAVING new video info for #{current_user.email} during upload.  REASON: The video id passed in was not found within the current_user's videos. Maybe they tried modifying someone else's video by changing the form params?") if Rails.env.production?
        render :json => { :error => "There was an error saving your video. The parameters did not match up with what was expected.  We have been notified of this issue." },
               :status => :unprocessable_entity
      end
    end
  end
  
  # PUT /:username/videos/:id
  def update 
    @video ||= current_user.videos.find_by_id(params[:id])   
    if @video
      video_params = params[:video]
      video_params[:channel_id] = params[:channel_id]
      video_params[:channel_name] = params[:channel_name]
      video_params[:channel_is_private] = params[:channel_is_private]
      
      if @video.update_attributes(video_params)
        # Create new tags/taggings if necessary
        @video.create_taggings(params[:video_tags])

        if params[:redirect].blank?
          # new video form
          render :json => { :channel_select => render_to_string( :partial => 'videos/channel_options.html',
                                                                 :locals => { :@video => @video } ) }, 
                 :status => :accepted
        else
          # update video form
          redirect_to(user_video_path(current_user, @video))
        end
      else
        render :json => { :error => get_errors_for_class(@video) },
               :status => :unprocessable_entity
      end
    else
      render :json => { :error => "That video could not be found" },
             :status => :not_found
    end
  end
  
  # PUT /:username/video_upload_error
  # we had an uploading error so capture the state
  def upload_error
    vg = Video.find_by_id(params[:video_id]).video_graph rescue nil
    if vg
      vg.set_status(VideoGraph::UPLOADING_ERROR)
      detailed_error_msg = "Error: #{params[:error_message]} ; File Size: #{params[:file_size]} ; Percent Uploaded: #{params[:percent_uploaded]} ; Average Speed: #{params[:average_speed]} ; Moving Average Speed: #{params[:moving_average]}"
      vg.error_message = detailed_error_msg
      vg.save
      # save the error for QA tracking and analytics
      vg.video_errors.create(:user_id => vg.user_id, :error_status => vg.status, :error_message => detailed_error_msg)
      
      Airbrake.notify(:error_class => "Logged Error", :error_message => "UPLOAD ERROR: User #{vg.user_id} just had an uploading error... #{detailed_error_msg}") if Rails.env.production?
    end
    render :nothing => true, :status => :accepted
  end
  
  private
    # Sets a video based on the params (if it exists)
    def set_video_based_on_user
      video_id = params[:video_id] || params[:id]

      begin
        if current_user?(@user)
          @video ||= @user.videos.where(:id => video_id).joins(:video_graph).where(:video_graphs => { :status => Video.statuses_to_show_to_current_user }).first
        else
          @video ||= @user.videos.where(:id => video_id).joins(:video_graph).where(:video_graphs => { :status => VideoGraph.get_status_number(:ready) }).first
        end
      rescue ActiveRecord::StatementInvalid
        @video = nil
      end
      
      render(:template => "errors/error_404", :status => 404) if @video.blank?
    end
    
end

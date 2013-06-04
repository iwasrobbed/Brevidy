class PublicVideosController < ApplicationController
  include ApplicationHelper
  
  skip_before_filter :http_authenticate, :site_authenticate
  
  # GET /embed/:public_token
  def embed
    if params[:public_token]
      # Only accept the first 11 characters as the public token
      @video ||= Video.where('public_token = ?', params[:public_token].strip.first(11)).first
      
      if @video && @video.is_status?(VideoGraph::READY)
        render :template => "public_videos/embed",
               :status => :ok,
               :layout => "empty"
        
        # Create an entry for a video being played if it's not a known bot
        # but give it an event_creator_id of 0 so we can distinguish it as an external play
        UserEvent.create(:event_type => UserEvent.event_type_value(:video_play), 
                         :event_object_id => @video.id,
                         :user_id => @video.user_id,
                         :event_creator_id => 0)
      else
        # show an error page if we couldn't find the video or the 
        # video is not yet done uploading/processing/etc
        render :template => "errors/error_404", :status => 404
      end
    else
      # no public token passed in
      render :template => "errors/error_404", :status => 404
    end
  end
  
  # GET p/:public_token
  def show
    if params[:public_token]
      # Only accept the first 11 characters as the public token
      @video ||= Video.where('public_token = ?', params[:public_token].strip.first(11)).first
      
      if @video && @video.is_status?(VideoGraph::READY)
        @user = get_object_owner(@video)
        @latest_featured_videos = @user.featured_videos.limit(4)
        
        render 'videos/show'
      else
        # show an error page if we couldn't find the video or the 
        # video is not yet done uploading/processing/etc
        render :template => "errors/error_404", :status => 404
      end
    else
      # no public token passed in
      render :template => "errors/error_404", :status => 404
    end
  end
  
end
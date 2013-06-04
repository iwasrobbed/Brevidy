class ChannelsController < ApplicationController
  include ApplicationHelper
  
  before_filter :site_authenticate, :except => [:index, :show, :show_by_token_access]
  before_filter :set_user, :except => [:show_by_token_access]
  before_filter :verify_current_user_is_not_blocked, :only => [:index]
  before_filter :set_channel, :only => [:edit, :destroy, :show, :update]
  before_filter :verify_user_owns_channel, :only => [:destroy, :edit, :update]
  before_filter :set_featured_videos, :only => [:edit, :edit_featured_videos, :index, :show]
  before_filter :verify_user_can_access_channel, :only => [:show]
  
  # GET /:username/channels/:id-slug-name-goes-here/edit
  def edit
    @subscribers = @channel.subscribers_as_people.paginate(:page => params[:page], :per_page => 100)
    
    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end
  end
  
  # GET /:username/edit_featured_videos
  def edit_featured_videos
    # Do a quick security check to verify user
    render(:template => "errors/error_404", :status => 404) and return unless current_user?(@user)
    
    @featured_videos = current_user.featured_videos.paginate(:page => params[:page], :per_page => 20, :order => 'featured_at DESC')
    
    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end
  end
  
  # DELETE /:username/channels/:id-slug-name-goes-here
  def destroy
    if @channel.featured?
      render :json => {:error => "You cannot delete your featured channel."}, :status => :unauthorized
    else
      @channel.destroy and redirect_to user_channels_path(current_user)
    end
  end
  
  # GET /:username/channels
  def index  
    @channels = @user.channels.paginate(:page => params[:page], :per_page => 9, :order => 'created_at DESC')
    
    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end
  end
  
  # GET /:username/channels/:id-slug-name-goes-here
  def show    
    if current_user.blank? || !current_user?(@user)
      # Only show videos that are in a :ready state
      @videos ||= @channel.videos.joins(:video_graph).where(:video_graphs => { :status => VideoGraph.get_status_number(:ready) }).
                           paginate(:page => params[:page], :per_page => 10, :order => 'created_at DESC')
    else    
      # Show all videos except ones that are uploading
      @videos ||= @channel.videos.joins(:video_graph).where(:video_graphs => { :status => Video.statuses_to_show_to_current_user }).
                           paginate(:page => params[:page], :per_page => 10, :order => 'created_at DESC')
    end
      
    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end
  end
  
  # GET /c/:public_token
  def show_by_token_access
    if params[:public_token]
      # Only accept the first 50 characters as the public token
      @channel ||= Channel.where('public_token = ?', params[:public_token].strip.first(50)).first
      
      if @channel
        @viewing_via_token_access = true
        @user = get_object_owner(@channel)
        @latest_featured_videos = @user.featured_videos.limit(4)
        # Only show videos that are in a :ready state
        @videos ||= @channel.videos.joins(:video_graph).where(:video_graphs => { :status => VideoGraph.get_status_number(:ready) }).
                             paginate(:page => params[:page], :per_page => 10, :order => 'created_at DESC')
                           
        respond_to do |format|
          params[:page].to_i > 1 ? format.js { render 'channels/show.js' } : format.html { render 'channels/show.html' }
        end
      else
        # show an error page if we couldn't find the channel
        render :template => "errors/error_404", :status => 404
      end
    else
      # no public token passed in
      render :template => "errors/error_404", :status => 404
    end
  end
  
  # PUT /:username/channels/:id-slug-name-goes-here/update
  def update
    # Update privacy params
    if params[:privacy]
      @channel.private = params[:privacy]
      send_back_link = true
    end
    
    # Update name
    if params[:title]
      @channel.title = params[:title]
    end
    
    if @channel.save
      if send_back_link
        render :json => { :new_link => user_channel_url(@user, @channel, :privacy => @channel.private? ? "false" : "true") }, 
               :status => :accepted
      else
        render :nothing => true, :status => :accepted
      end
    else
      render :json => { :error => get_errors_for_class(@channel).to_sentence }, 
             :status => :unprocessable_entity
    end
  end
  
  # PUT /:username/update_featured_videos
  def update_featured_videos
    @video ||= current_user.videos.find_by_id(params[:video_id])
    if @video
      if @video == current_user.featured_videos.first
        render :json => { :error => "That video is already at the top of your featured videos list :)" }, 
               :status => :unprocessable_entity
      else
        @video.featured_at = Time.now
        @video.save
        render :json => { :featured_video => render_to_string( :partial => 'shared/featured_video.html',
                                                               :locals => { :featured_video => @video }) }, 
               :status => :accepted
      end
    else
      render :json => { :error => "Either that video does not exist or you do not have permission to move it." }, 
             :status => :unprocessable_entity
    end
  end
  
end
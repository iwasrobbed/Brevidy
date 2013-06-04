class ApplicationController < ActionController::Base
  protect_from_forgery
  
  # Handles session / authentication
  include SessionsHelper
  
  # Order of before_filters is important
  before_filter :http_authenticate, :site_authenticate, :ensure_the_user_is_not_deactivated
  
  # Use HTTP BASIC authenticattion for test and development environments
  def http_authenticate
    if Rails.env.staging?
      authenticate_or_request_with_http_basic do |username, password|
        (username == Brevidy::Application::HTTP_AUTH_USERNAME && password == Brevidy::Application::HTTP_AUTH_PASSWORD) ||
        (username == Brevidy::Application::HTTP_AUTH_ZEN_USERNAME && password == Brevidy::Application::HTTP_AUTH_ZEN_PASSWORD)
      end
    end
  end
  
  # Allows redirecting for AJAX calls as well as normal calls
  def redirect_to(options = {}, response_status = {})
    if request.xhr?
      render(:update) {|page| page.redirect_to(options)}
    else
      super(options, response_status)
    end
  end
  
  # Returns all errors for a given class name (klass)
  def get_errors_for_class(klass)
    if klass.errors.any?
      klass.errors.full_messages.each do |msg|
        msg
      end
    end
  end
  
  # Handles unauthorized CSRF tokens
  def handle_unverified_request
    super # call the default behaviour which resets the session
    cookies.delete(:remember_token)
    redirect_to :login
  end
  
  #############
  ## FILTERS ##
  #############
  
  # Sets instance variables for @user based on params
  def set_user
    @user ||= User.find_by_username(params[:username])
    render(:template => "errors/error_404", :status => 404) if @user.blank?
  end
  
  # Sets instance variables for @video based on params
  def set_video
    @video ||= @user.videos.find_by_id(params[:video_id])
    render(:template => "errors/error_404", :status => 404) if (@video.blank? || !@video.is_status?(VideoGraph::READY))
  end
  
  # Sets a channel based on the params (if it exists)
  def set_channel
    channel_id = params[:channel_id] || params[:id]
    @channel ||= @user.channels.find_by_id(channel_id) 
    render(:template => "errors/error_404", :status => 404) if @channel.blank?
  end
  
  # Show the 4 latest featured videos for this user
  def set_featured_videos
    @latest_featured_videos = @user.featured_videos.limit(4)
  end
  
  # Verifies that a given user is not blocking the current_user
  def verify_current_user_is_not_blocked
    unless current_user.blank? || current_user?(@user)
      render(:template => "errors/error_404", :status => 404) if Blocking.where(:requesting_user => @user.id, :blocked_user => current_user.id).exists?
    end
  end
  
  # Verifies that a given user can access the channel containing the video
  def verify_user_can_access_channel
    unless user_can_access_channel
      if (params[:controller] == "channels" && params[:action] == "show")
        render(:template => "errors/private_channel", :status => 404)
      else
        render(:template => "errors/error_404", :status => 404)
      end
    end
  end
  
  # Verifies that a given user can access either the channel or the videos within the channel
  def verify_user_can_access_channel_or_video
    public_token = params[:channel_token]
    user_can_access_either_one = (public_token and public_token.strip == @video.channel.public_token) || user_can_access_channel
    
    render(:template => "errors/error_404", :status => 404) unless user_can_access_either_one
  end
  
  # Helper for auth verifications
  def user_can_access_channel
    return @channel.is_accessible_by(current_user) if @channel
    return @video.channel.is_accessible_by(current_user) if @video
  end
  
  # Verifies the user owns the channel
  def verify_user_owns_channel
    render(:template => "errors/error_404", :status => 404) unless current_user_owns?(@channel)
  end
  
  # Verifies the user owns the page
  def verify_user_owns_page
    render(:template => "errors/error_404", :status => 404) unless current_user?(@user)
  end
  
  # Verifies the user owns the video
  def verify_user_owns_video
    render(:template => "errors/error_404", :status => 404) unless current_user_owns?(@video)
  end
  
  # Redirects the user to their subscription stream if they are logged in
  def redirect_to_stream_if_logged_in
    redirect_to user_stream_path(current_user) if signed_in?
  end
  
  private
    # A before_filter to deny access to certain controller actions 
    # based on if the user is logged in or not.
    def site_authenticate
      deny_access unless signed_in?
    end
    
    # A before_filter to check if the current_user has been deactivated.
    # If so, they are shown an error message and told to check their email
    # for the reason why.
    def ensure_the_user_is_not_deactivated
      unless current_user.nil?
        if current_user.is_deactivated
          sign_out
          render(:template => "errors/error_deactivated", :status => 401)
        end
      end
    end
    
    # A before_filter to check if the user is using a modern web browser.
    # If they are not, we show an error message and ask them to upgrade to
    # one of the supported browsers.
    def check_for_modern_browser
      if browser.ie6? || browser.ie7?
        render(:template => "errors/error_old_browser", :status => 401)
      end
    end
end

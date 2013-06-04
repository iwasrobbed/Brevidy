class UsersController < ApplicationController
  require 'securerandom'

  # needed for truncate method
  include ActionView::Helpers::TextHelper
  
  before_filter :site_authenticate, :only => [:block, :edit, :edit_banner, :latest_activity, :new_image, 
                                              :new_image_status, :subscriptions_stream, :unblock, :update, 
                                              :update_background_image, :update_banner_from_gallery, :update_notifications, 
                                              :update_password]
  before_filter :redirect_to_stream_if_logged_in, :only => [:create, :forgotten_password, :new, :reset_password, :signup, 
                                                            :validate_forgotten_password, :validate_reset_password] 
  before_filter :set_user, :except => [:create, :forgotten_password, :index, :new, :signup, :username_availability, :validate_forgotten_password]
  before_filter :verify_current_user_is_not_blocked, :only => [:show]
  before_filter :verify_user_owns_page, :only => [:edit, :edit_banner, :new_image, :new_image_status, :subscriptions_stream, 
                                                  :update, :update_background_image, :update_banner_from_gallery, :update_notifications, 
                                                  :update_password]
  before_filter :set_featured_videos, :only => [:show, :subscriptions_stream]
  before_filter :verify_tokens_match_and_token_is_fresh, :only => [:reset_password, :validate_reset_password]
  
  # Caching
  caches_action :new
  
  # POST /:username/block
  def block
    blocking = Blocking.where(:requesting_user => current_user.id, :blocked_user => @user.id).first
    if blocking
      render :json => { :error => "You are already blocking that user." }, 
             :status => :unprocessable_entity
    else
      current_user.block!(@user)
      render :nothing => true, :status => :created
    end
  end
  
  # POST /users
  def create
    @user = User.new(params[:user])

    if @user.save
      sign_in @user
      
      # associate them w/ a social login account if necessary
      unless params[:social_signup].blank?
        @user.associate_with_social_account(params, cookies[:social_image_url], cookies[:social_bio])
      end
      
      respond_to do |format|
        format.html { redirect_to user_stream_path(current_user) }
        format.json { render :json => { :success => true, 
                                        :message => nil,
                                        :user_id => @user.id }, :status => :created }
      end
      
      UserMailer.delay.celebrate_new_user(@user) if Rails.env.production?
    else
      # return errors via AJAX
      respond_to do |format|
        format.js
        format.json { render :json => { :success => false, 
                                        :message => get_errors_for_class(@user).to_sentence,
                                        :user_id => false }, :status => :unprocessable_entity }
      end
    end
  end
  
  # GET /:username/account
  def edit
    @browser_title ||= "Edit Account"
    @facebook_connected = SocialNetwork.find_by_user_id_and_provider(current_user.id, "facebook") 
    @twitter_connected = SocialNetwork.find_by_user_id_and_provider(current_user.id, "twitter") 
  end
  
  # GET /:username/edit_banner
  def edit_banner
    @banner_images = BannerImage.where(:active => true)
  end
  
  # GET /account/forgotten_password
  def forgotten_password
    @browser_title ||= "Forgotten Password"
    @show_password_reset = false
 
    respond_to do |format|
      format.html { render(:template => "users/forgotten_password", :status => :ok, :layout => "signed_out") }
    end
  end
  
  # GET /users
  def index
    @browser_title ||= "Find People"
    
    # show the 4 latest featured videos for the Explore page
    #@latest_featured_videos = User.find_by_username("brevidy").featured_videos.limit(4)
    
    @latest_featured_videos = []
    
    respond_to do |format|
      format.html
    end
  end
  
  # Main landing page w/ social sign up buttons
  # GET brevidy.com
  def new
    @invitation ||= InvitationLink.handle_invite_token(params[:invitation_token])
    cookies[:invitation_token] = params[:invitation_token] if params[:invitation_token]
    
    respond_to do |format|
      format.html { render(:template => "users/new", :status => :ok, :layout => "signed_out") }
    end
  end
  
  # GET /:username/account/image_status
  def new_image_status
    if current_user.image_status == 'processing'
      render :json => { :job_status => 'processing' },
             :status => :ok
    elsif current_user.image_status == 'success'
      # refresh page to show new image
      if params[:media_type] == 'banner'
        redirect_to user_edit_banner_path(current_user)
      else
        redirect_to user_account_path(current_user)
      end
    elsif current_user.image_status == 'error'
      # we had an issue updating the image
      render :json => { :job_status => 'error' },
             :status => :ok
    else
      # we had an unknown state
      render :json => { :job_status => 'error' },
             :status => :ok
    end
  end
  
  # PUT /:username/account/image
  def new_image
    if params[:filename].blank? || params[:media_type].blank?
      Airbrake.notify(:error_class => "Logged Error", :error_message => "USER IMAGE: Error SAVING image for #{current_user.email}.  REASON: Filename or media_type (image or banner) was blank.") if Rails.env.production?
      render :json => { :error => "There was an error saving your new image.  We have been notified of this issue." }, 
             :status => :unprocessable_entity
    else  
      current_user.update_attribute(:image_status, 'processing')
      new_temp_image = params[:filename]

      if params[:media_type] == 'banner'
        # It's a banner image
        old_banner_image = current_user.read_attribute(:banner_image)

        # Kick off resizing and setting the new image
        # Also pass in the old image and new temp file so we can clean up after ourselves on S3
        current_user.set_new_user_image(old_banner_image, new_temp_image, true)
      elsif params[:media_type] == 'image'
        # It's a profile image
        old_image = current_user.read_attribute(:image)

        # Kick off resizing and setting the new image
        # Also pass in the old image and new temp file so we can clean up after ourselves on S3
        current_user.set_new_user_image(old_image, new_temp_image, false)
      else
        Airbrake.notify(:error_class => "Logged Error", :error_message => "There was a bad media_type passed in (#{params[:media_type]}) when saving a new image for #{current_user.email}.") if Rails.env.production?
        return
      end
      
      # return :ok back to the browser so it can start polling
      # the image status to check when processing is complete
      #
      # we use :start_polling to tell the uploader to only do this
      # for images and not for videos
      render :json => { :start_polling => 'true' }, 
             :status => :ok
    end
  end
  
  # POST /:username/reset_password
  def reset_password
    if params[:password] == params[:password_confirmation]
      # New passwords match so reset it
      @user.update_attributes(:password => params[:password])
      User.should_encrypt_password = true
      if @user.save
        User.should_encrypt_password = false
        sign_in @user
        
        # Clear out the reset token so it can't be reused
        @user.reset_token = ""
        @user.save
        
        redirect_to current_user and return
        
      else
        flash.now[:error] = get_errors_for_class(@user)
        @show_password_reset = true
      end
      User.should_encrypt_password = false
  
    else
      flash.now[:error] = "Passwords do not match.  Please re-enter and confirm your new password."
      @show_password_reset = true
    end
  
    respond_to do |format|
      format.html { render(:template => "users/forgotten_password", :status => :ok, :layout => "signed_out") }
    end
  end
  
  # GET /:username
  # GET /:username.js
  def show
    @browser_title ||= @user.name

    if current_user.blank? || !current_user?(@user)
      # Only show public videos that are complete
      @videos ||= @user.public_videos.paginate(:page => params[:page], :per_page => 10, :order => 'created_at DESC')
    else
      # Show all videos (public and private) except ones that are uploading
      @videos ||= @user.all_videos.paginate(:page => params[:page], :per_page => 10, :order => 'created_at DESC')
    end

    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end
  end
  
  # Secondary sign up page for handling errors and showing old fashioned signup form
  # GET /users/signup
  def signup
    @user = User.new
    @invitation ||= InvitationLink.handle_invite_token(params[:invitation_token])
    
    respond_to do |format|
      format.html { render(:template => "users/signup", :status => :ok, :layout => "signed_out") }
    end
  end
  
  # GET /:username/stream
  # GET /:username/stream.js
  def subscriptions_stream
    @browser_title ||= @user.name
    @videos ||= current_user.all_videos_for_subscriptions.paginate(:page => params[:page], :per_page => 10, :order => 'created_at DESC')

    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end
  end
  
  # POST /:username/unblock
  def unblock
    blocking = Blocking.where(:requesting_user => current_user.id, :blocked_user => @user.id).first
    if blocking
      if blocking.destroy
        render :nothing => true, :status => :ok
      else
        render :json => { :error => "There was an issue unblocking that person.  We have been notified of this issue." }, 
               :status => :not_found
        Airbrake.notify(:error_class => "Logged Error", :error_message => "UNBLOCK: User (#{current_user.email}) was unable to unblock another user (#{@user.email})") if Rails.env.production?
      end
    else
      render :json => { :error => "You are not currently blocking that user." }, 
             :status => :unprocessable_entity
    end
  end
  
  # PUT /:username/account/update
  def update
    # format the new birthday
    new_birthday = "#{params[:birthday_year]}-#{params[:birthday_month]}-#{params[:birthday_day]}"
    # cache the old username
    old_username = current_user.username
    
    # update the other attributes
    if current_user.update_attributes(params[:user]) && current_user.update_attributes(:birthday => new_birthday)
      if current_user.username != old_username
        current_user.update_attribute(:username_changed_at, DateTime.now)
        redirect_to user_account_path(current_user) 
      else  
        render :nothing => true, :status => :accepted
      end
    else
      render :json => { :error => get_errors_for_class(current_user).to_sentence }, 
             :status => :unprocessable_entity
    end
  end
  
  # PUT /:username/update_background_image
  def update_background_image
    background_image_id = params[:background_image_id]
    if background_image_id.blank?
      render :json => { :error => "Sorry, but we could not set your background image for you." }, 
             :status => :unprocessable_entity
      Airbrake.notify(:error_class => "Logged Error", :error_message => "USER BACKGROUND: Could not set a background image since the background_image_id passed in was blank.") if Rails.env.production?
    else
      # Make sure a valid ID was passed in
      if current_user.update_attributes(:background_image_id => background_image_id.to_i)
        render :json => { :background_image_id => background_image_id }, 
               :status => :accepted
      else
        render :json => { :error => "Sorry, but we could not set your background image for you." }, 
               :status => :unprocessable_entity
        Airbrake.notify(:error_class => "Logged Error", :error_message => "USER BACKGROUND: Could not set a background image since the background_image_id passed in was invalid.") if Rails.env.production?
      end
    end
  end
  
  # PUT /:username/update_banner_from_gallery
  def update_banner_from_gallery
    banner_id = params[:banner_image_id]
    if banner_id.blank?
      render :json => { :error => "Sorry, but we could not set your banner image for you." }, 
             :status => :unprocessable_entity
      Airbrake.notify(:error_class => "Logged Error", :error_message => "USER BANNER: Could not set a user banner from the gallery since the banner ID passed in was blank.") if Rails.env.production?
    else
      # Make sure a valid ID was passed in
      if BannerImage.where(:id => banner_id, :active => true).exists?
        current_user.update_attributes(:banner_image_id => banner_id)
        render :json => { :image_path => current_user.get_banner_image_url(banner_id) }, 
               :status => :accepted
      else
        render :json => { :error => "Sorry, but we could not set your banner image for you." }, 
               :status => :unprocessable_entity
        Airbrake.notify(:error_class => "Logged Error", :error_message => "USER BANNER: Could not set a user banner from the gallery since the banner ID passed in was invalid or for a banner that is no longer active.") if Rails.env.production?
      end
    end
  end
  
  # PUT /:username/account/notifications
  def update_notifications
    the_settings = current_user.setting
    if the_settings.update_attributes(params[:user])  
      render :nothing => true, 
             :status => :accepted
    else
      render :json => { :error => get_errors_for_class(the_settings).to_sentence }, 
             :status => :unprocessable_entity
    end
  end
  
  # PUT /:username/account/password
  def update_password      
    puts params[:old_password].strip
    if current_user.has_password?(params[:old_password].strip)
      new_password ||= params[:new_password].strip
      confirm_new_password ||= params[:confirm_new_password].strip
      if new_password == confirm_new_password
        User.should_encrypt_password = true
        if current_user.update_attributes(:password => new_password)
          render :nothing => true, :status => :accepted
        else
          render :json => { :error => get_errors_for_class(current_user).to_sentence }, 
                 :status => :unprocessable_entity
        end
        User.should_encrypt_password = false 
      else
        render :json => { :error => "Your new password does not match the confirmation password.  Please re-type them." }, 
               :status => :unprocessable_entity
      end
    else
      render :json => { :error => "Your old password does not match the password we have on record." }, 
             :status => :unprocessable_entity
    end
  end
  
  # GET /username_availability
  def username_availability
    if params[:username].blank?
      render :json => { :error => "No username was passed in." }, 
             :status => :unprocessable_entity
    else
      username = params[:username].downcase.strip
      if (username.length > User::USERNAME_LENGTH) || !User::USERNAME_REGEX.match(username) || !User.verify_username_is_acceptable(username) || User.where(:username => username).exists?
        render :json => { :availability_text => "not available" }, 
               :status => :ok
      else
        render :json => { :availability_text => "available" }, 
               :status => :ok
      end
    end
  end
  
  # POST /account/validate_forgotten_password
  def validate_forgotten_password
    @show_password_reset = false
    
    if params[:email].blank?
      flash.now[:error] = "Please enter an email address." and return
    elsif is_not_a_valid_email(params[:email])
      flash.now[:error] = "Email address is invalid.  Please enter a valid email address." and return
    else            
      forgetful_user = User.find_by_email(params[:email])
      if forgetful_user
        # Generate reset token for the forgetful user
        forgetful_user.reset_token = generate_reset_token
        # Record when pw reset was requested for token expiration
        forgetful_user.pw_reset_timestamp = Date.today
        
        if forgetful_user.save 
          # Send email
          UserMailer.delay(:priority => 0).reset_password_instructions(forgetful_user)
          
          # Show flash message
          flash.now[:success] = "We have sent password reset instructions to that email address."
        else
          flash.now[:error] = "There was an error processing your password reset request.  We have been notified of this issue."
          Airbrake.notify(:error_class => "Logged Error", :error_message => "Could not save reset_token (#{forgetful_user.reset_token}) for User (#{forgetful_user.email}).") if Rails.env.production?
        end 
      else
        flash.now[:error] = "We could not find a user with that email address."
      end
    end
    
    respond_to do |format|
      format.html { render(:template => "users/forgotten_password", :status => :ok, :layout => "signed_out") }
    end
  end
  
  # GET /:username/validate_reset_password?token=[token]
  def validate_reset_password
    @browser_title ||= "Reset Password"
    @show_password_reset = true
    
    respond_to do |format|
      format.html { render(:template => "users/forgotten_password", :status => :ok, :layout => "signed_out") }
    end
  end
  
  
  private 
    # Verifies the user's reset password token matches and is less than 2 days old
    def verify_tokens_match_and_token_is_fresh
      @token = params[:token]
      invalid_token_msg = "The reset password link you are attempting to use is invalid or has expired.  Please enter your email below to generate a new link."
      
      # Make sure the token isn't blank
      if @token.blank?
        @show_password_reset = false
        flash.now[:error] = invalid_token_msg
        render(:template => "users/forgotten_password", :status => :ok, :layout => "signed_out") and return
      end
      
      # See if the token is older than 2 days (it's expired if so)
      unless @user.pw_reset_timestamp.blank?
        date_then = Date.new(@user.pw_reset_timestamp.year, @user.pw_reset_timestamp.month, @user.pw_reset_timestamp.day)
        @freshToken = (Date.today - date_then).to_i <= 2
      end
      
      # Make sure the tokens match up and the token is less than 2 days old
      unless @token == @user.reset_token && @freshToken
        # Clear the reset token since it's expired or someone is trying to guess it            
        @user.reset_token = ""
        @user.save  
        
        # Show a flash message and render the page
        @show_password_reset = false
        flash.now[:error] = invalid_token_msg
        render(:template => "users/forgotten_password", :status => :ok, :layout => "signed_out")
      end
    end
    
    # Checks if email is valid
    def is_not_a_valid_email(email)
      reg = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
      return (reg.match(email))? false : true
    end
    
    # Generates a 32 character random string for resetting the user's password
    def generate_reset_token
      loop do
        token = SecureRandom.base64(32).tr('+/=', 'xyz')
        break token unless User.where(:reset_token => token).exists?
      end
    end
    
end

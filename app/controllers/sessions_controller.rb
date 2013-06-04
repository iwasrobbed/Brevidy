class SessionsController < ApplicationController
  skip_before_filter :site_authenticate
  skip_before_filter :ensure_the_user_is_not_deactivated, :only => [:destroy]
  
  def new
    if signed_in?
      redirect_to user_stream_path(current_user)
    else
      @browser_title = "Login"
      respond_to do |format|
        format.html { render(:template => "sessions/new", :status => :ok, :layout => "signed_out") }
      end
    end
  end
  
  # handles social signups / logins / associations
  def create_social_session
    social_params ||= request.env["omniauth.auth"]
    if social_params
      if signed_in?
        # user is associating their FB / Twitter account with their Brevidy account        
        new_network ||= current_user.social_networks.new(:provider => social_params["provider"], :uid => social_params["uid"], :token => social_params["credentials"]["token"], :token_secret => social_params["credentials"]["secret"])
        
        respond_to do |format|
          if new_network.save
            format.html { redirect_to user_account_path(current_user) }
            format.json { render :json => { :success => true,
                                            :message => nil,
                                            :user_id => current_user.id }, 
                                 :status => :created }
          else
            error_message ||= get_errors_for_class(new_network).to_sentence
            format.html { flash[:error] = error_message; redirect_to user_account_path(current_user) }
            format.json { render :json => { :success => false,
                                            :message => error_message,
                                            :user_id => current_user.id }, 
                                 :status => :unprocessable_entity }
          end
        end
      else
        # user is either logging in or signing up via FB / Twitter
        # check if a user with that UID already exists
        social_credentials = SocialNetwork.find_by_provider_and_uid(social_params["provider"], social_params["uid"])
        
        if social_credentials.blank?
          # delete any old social image cookies so we don't set an incorrect image from a prior session
          cookies.delete(:social_image_url)
          cookies.delete(:social_bio)
          
          # create a new user and redirect to step 2 of the signup process
          @user = User.create_via_fb_or_twitter(social_params)
          # set cookies to remember the user's image and bio so we can set it after they are created
          case social_params["provider"]
            when "facebook"
              cookies[:social_image_url] = social_params["user_info"]["image"].gsub("type=square", "type=large") rescue nil
              cookies[:social_bio] = social_params["extra"]["user_hash"]["bio"] rescue nil
            when "twitter"
              cookies[:social_image_url] = social_params["extra"]["user_hash"]["profile_image_url_https"].gsub("_normal", "") rescue nil
              cookies[:social_bio] = social_params["extra"]["user_hash"]["description"] rescue nil
          end
          
          respond_to do |format|
            format.html { render(:template => "users/signup", 
                                 :status => :ok, 
                                 :layout => "signed_out",
                                 :locals => { :user => @user,  
                                              :provider => social_params["provider"],
                                              :uid => social_params["uid"],
                                              :oauth_token => social_params["credentials"]["token"],
                                              :oauth_token_secret => social_params["credentials"]["secret"],
                                              :social_signup => "true" }) }
          end
        else
          # user already exists with that UID/provider combo, so they just want to login
          sign_in User.find_by_id(social_credentials.user_id)
          respond_to do |format|
            format.html { redirect_back_or user_stream_path(current_user) }
          end
        end # end blank?
      end # end signed_in?
    else
      respond_to do |format|
        error_message = "There was an error communicating with Facebook or Twitter. Please try again in a few minutes!"
        format.html { flash[:error] = error_message; redirect_to :login }
        format.json { render :json => { :success => false,
                                        :message => error_message,
                                        :user_id => false }, 
                             :status => :unauthorized }
      end
    end # end check for social params
  end
  
  # handles regular logins (i.e. w/ email / password)
  def create
    # strip fields and downcase email
    prepare_params_for_login
  
    user = User.authenticate(params[:email],
                             params[:password])
  
    if user.nil?
      respond_to do |format|
        error_message = "Invalid login credentials."
        format.html { flash[:error] = error_message; redirect_to :login }
        format.json { render :json => { :success => false,
                                        :message => error_message,
                                        :user_id => false }, 
                             :status => :unauthorized }
      end
    else
      sign_in user
      respond_to do |format|
        format.html { redirect_back_or user_stream_path(current_user) }
        format.json { render :json => { :success => true,
                                        :message => nil,
                                        :user_id => user.id }, 
                             :status => :created }
      end
    end
  end
  
  def destroy
    sign_out
    redirect_to root_path
  end
end

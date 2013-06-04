class ProfileController < ApplicationController
  skip_before_filter :site_authenticate, :only => [:index]
  before_filter :set_user
  before_filter :verify_current_user_is_not_blocked, :only => [:index]
  before_filter :set_featured_videos, :only => [:index]

  # GET /:username/profile
  def index
    @browser_title ||= @user.name
    @profile = @user.profile
  end

  # PUT /:username/profile/:id
  def update
    profile = current_user.profile

    if params[:profile].blank?
      render :json => { :error => "There was no profile data passed in so your profile could not be saved." }, 
             :status => :unprocessable_entity
    else
      if profile.update_attributes(params[:profile])
        render :json => { :html => profile.categories_to_hash('html'),
                          :text => profile.categories_to_hash('text') },
               :status => :accepted
      else
        render :json => { :error => get_errors_for_class(profile).to_sentence }, 
               :status => :unprocessable_entity
      end
    end
  end

end

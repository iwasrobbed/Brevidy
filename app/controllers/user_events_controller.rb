class UserEventsController < ApplicationController  
  before_filter :set_user, :verify_user_owns_page, :set_featured_videos
  
  # GET /:username/latest_activity
  def show
    @browser_title ||= "Latest Activity"
    # return all user events other than video plays
    @user_events = @user.notifications_to_show_user.paginate(:page => params[:page], :per_page => 25, :order => 'created_at DESC')
    
    # mark all user events for the current user as "seen"
    UserEvent.where(:user_id => current_user.id, :seen_by_user => false).update_all(:seen_by_user => true) unless current_user.notifications_count == 0
    
    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end
  end

end
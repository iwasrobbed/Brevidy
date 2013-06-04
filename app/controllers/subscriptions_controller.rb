class SubscriptionsController < ApplicationController
  include ApplicationHelper
  
  before_filter :site_authenticate, :except => [:subscribers, :subscriptions]
  before_filter :set_user
  before_filter :set_channel, :except => [:subscribers, :subscriptions]
  before_filter :verify_current_user_is_not_blocked, :only => [:create, :destroy, :subscribers, :subscriptions]
  before_filter :verify_user_owns_channel, :only => [:handle_access_request, :remove_subscriber]
  before_filter :set_featured_videos, :only => [:subscribers, :subscriptions]
  
  # POST /:username/channels/:id-slug-name-goes-here/subscribe
  def create
    subscription ||= @channel.subscribe!(current_user)
    
    if subscription.errors.any?
      errors = get_errors_for_class(subscription).to_sentence
      if errors.include?("requesting permission")
        render :json => { :requesting_permission => true  },
               :status => :ok
      else
        render :json => { :error => errors },
               :status => :unprocessable_entity
      end
    else
      render :json => { :button => render_to_string( :partial => "channels/button_unsubscribe.html" ,
                                                     :locals => { :user => current_user,
                                                                  :channel => @channel,
                                                                  :button_size => params[:ref] } ) },
             :status => :created
    end
  end
  
  # DELETE /:username/channels/:id-slug-name-goes-here/unsubscribe
  def destroy
    subscription_was_destroyed ||= @channel.unsubscribe!(current_user)
    
    if subscription_was_destroyed
      is_private = @channel.private?
      render :json => { :button => render_to_string( :partial => "channels/button_subscribe.html" ,
                                                     :locals => { :user => current_user,
                                                                  :channel => @channel,
                                                                  :is_private => is_private,
                                                                  :button_size => params[:ref] } ),
                        :is_private => is_private,
                        :private_area_message => is_private ? render_to_string(:partial => "channels/private_area_message.html") : "" }, 
             :status => :ok
    else
      render :json => { :error => "You are not currently subscribed to this channel." },
             :status => :not_found
    end
  end
  
  # GET /:username/channels/:id-slug-name-goes-here/request_access?approved=t&token=some_token_here
  # GET /:username/channels/:id-slug-name-goes-here/request_access?ignored=t&token=some_token_here
  def handle_access_request
    channel_request = ChannelRequest.where(:channel_id => @channel.id, :token => params[:token]).first
    if channel_request.blank?
      flash[:error] = "Sorry, but we were unable to find a request to access this channel. You may have already approved it or it may have been cancelled by the other user."
    else
      requesting_user = User.find_by_id(channel_request.user_id)
      if params[:approved]
        subscription ||= @channel.subscribe!(requesting_user, true)
      
        if subscription.errors.any?
          flash[:error] = get_errors_for_class(subscription).to_sentence
        else
          flash[:success] = "We have granted access to your private channel, #{@channel.title}, for #{requesting_user.name}"
        end
      elsif params[:ignored]
        channel_request.ignored = true
        channel_request.save
      
        flash[:notice] = "We have ignored the request to access your private channel, #{@channel.title}.  Keep in mind that #{requesting_user.name} will not be notified about this."
      else
        flash[:error] = "Sorry, but we were unable to handle this access request.  We have been notified about this issue."
        Airbrake.notify(:error_class => "Logged Error", :error_message => "PRIVATE CHANNEL ACCESS: The approved or ignored param was missing in the query string clicked by #{current_user.email}") if Rails.env.production?
      end
    end
  end
  
  # DELETE /:username/channels/:id-slug-name-goes-here/remove_subscriber?user_id=1234
  def remove_subscriber
    user_to_remove = User.find_by_id(params[:user_id])
    subscription_was_destroyed ||= @channel.unsubscribe!(user_to_remove) if user_to_remove
    
    if subscription_was_destroyed
      render :nothing => true, :status => :ok
    else
      render :json => { :error => "That person is not currently subscribed to this channel." },
             :status => :not_found
    end
  end
  
  # GET /:username/subscribers
  def subscribers
    @users = @user.subscribers_as_people.paginate(:page => params[:page], :per_page => 50, :order => 'created_at DESC')
    
    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end
  end
  
  # GET /:username/subscriptions
  def subscriptions
    @subscriptions = @user.channel_subscriptions.paginate(:page => params[:page], :per_page => 9, :order => 'created_at DESC')
    
    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end
  end

end
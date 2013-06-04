class SocialNetworksController < ApplicationController
  skip_before_filter :site_authenticate, :http_authenticate
  
  # POST /auth/deauthorize
  def deauthorize
    # Currently, only Facebook has a deauthorization callback
    request_params = params[:signed_request].split('.')
    encoded_signature = SocialNetwork.base64_url_decode(request_params[0])
    user_payload = ActiveSupport::JSON.decode(SocialNetwork.base64_url_decode(request_params[1]))
    Airbrake.notify(:error_class => "Non-Issue", :error_message => "Just letting you know that a user deauthorized Brevidy on Facebook :(  The user was #{User.find_by_id(SocialNetwork.where(:uid => user_payload['user_id'], :provider => 'facebook').first).id}") if Rails.env.production?
    
    render :nothing => true, :status => :ok
  end
  
  # DELETE /users/user_id/social_networks/:id
  def destroy    
    social_credentials = SocialNetwork.find_by_user_id_and_provider(current_user.id, params[:provider])
    respond_to do |format|
      if social_credentials.blank?
        error_message ||= "We could not find a #{params[:provider].capitalize} account associated with your Brevidy account."
        format.html { flash[:error] = error_message; redirect_to user_account_path(current_user) }
        format.json { render :json => { :success => false,
                                        :message => error_message,
                                        :user_id => current_user.id }, 
                             :status => :unprocessable_entity }
      else
        social_credentials.destroy
        format.html { redirect_to user_account_path(current_user) }
        format.json { render :json => { :success => true,
                                        :message => nil,
                                        :user_id => current_user.id }, 
                             :status => :ok }
      end 
    end
  end
  
end
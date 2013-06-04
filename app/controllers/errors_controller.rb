class ErrorsController < ApplicationController
  skip_before_filter :site_authenticate
  
  def error_social_auth
    render :template => "errors/error_social_auth", :status => 401
    Airbrake.notify(:error_class => "Logged Error", :error_message => "SOCIAL CREDENTIALS: There was an OmniAuth authentication failure.") if Rails.env.production?
  end
  
  def routing
    @browser_title ||= "Oops"
    render :template => "errors/error_404", :status => 404
  end
end
class PublicController < ApplicationController
  skip_before_filter :site_authenticate
  
  def faq
    @browser_title ||= "FAQ"
    render(:template => "public/faq", :status => :ok)
  end
  
  def video_faq
    @browser_title ||= "Video FAQ"
    render(:template => "public/video_faq", :status => :ok)
  end
  
  def video_guidelines
    @browser_title ||= "Video Guidelines"
    render(:template => "public/video_guidelines", :status => :ok)
  end
  
  def contact
    @browser_title ||= "Contact"
    render(:template => "public/contact", :status => :ok)
  end
  
  def privacy
    @browser_title ||= "Privacy Policy"
    render(:template => "public/privacy", :status => :ok)
  end
  
  def tos
    @browser_title ||= "Terms of Service"
    render(:template => "public/tos", :status => :ok)
  end
end
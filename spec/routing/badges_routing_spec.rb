require "spec_helper"
  
describe BadgesController do
  describe "routing" do
    # create a video associated with a user (by default)
    video = FactoryGirl.create(:video)
 
    it "recognizes and generates #badges_dialog /#{video.user.username}/videos/#{video.id}/badges" do
      { :get => "/#{video.user.username}/videos/#{video.id}/badges" }.should route_to(:controller => "badges", 
                                                                                      :action => "badges_dialog", 
                                                                                      :username => "#{video.user.username}",
                                                                                      :video_id => "#{video.id}")
    end
    
    it "recognizes and generates #create /#{video.user.username}/videos/#{video.id}/badges" do
      { :post => "/#{video.user.username}/videos/#{video.id}/badges" }.should route_to(:controller => "badges", 
                                                                                       :action => "create", 
                                                                                       :username => "#{video.user.username}",
                                                                                       :video_id => "#{video.id}")
    end
    
    it "recognizes and generates #destroy /#{video.user.username}/videos/#{video.id}/badges/1" do
      { :delete => "/#{video.user.username}/videos/#{video.id}/badges/1" }.should route_to(:controller => "badges", 
                                                                                           :action => "destroy", 
                                                                                           :id => "1",
                                                                                           :username => "#{video.user.username}",
                                                                                           :video_id => "#{video.id}")
    end
    
    it "recognizes and generates #index /#{video.user.username}/badges" do
      { :get => "/#{video.user.username}/badges" }.should route_to(:controller => "badges", 
                                                                   :action => "index",
                                                                   :username => "#{video.user.username}")
    end
  end
end
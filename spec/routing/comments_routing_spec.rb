require "spec_helper"
  
describe CommentsController do
  describe "routing" do
    # create a video associated with a user (by default)
    video = FactoryGirl.create(:video)
    
    it "recognizes and generates #create /#{video.user.username}/videos/#{video.id}/comments" do
      { :post => "/#{video.user.username}/videos/#{video.id}/comments" }.should route_to(:controller => "comments", 
                                                                                         :action => "create", 
                                                                                         :username => "#{video.user.username}",
                                                                                         :video_id => "#{video.id}")
    end
    
    it "recognizes and generates #destroy /#{video.user.username}/videos/#{video.id}/comments/1" do
      { :delete => "/#{video.user.username}/videos/#{video.id}/comments/1" }.should route_to(:controller => "comments", 
                                                                                             :action => "destroy", 
                                                                                             :id => "1",
                                                                                             :username => "#{video.user.username}",
                                                                                             :video_id => "#{video.id}")
    end
  end
end
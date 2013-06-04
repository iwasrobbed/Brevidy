require "spec_helper"
  
describe TagsController do
  describe "routing" do
    # create a video associated with a user (by default)
    video = FactoryGirl.create(:video)
    
    it "recognizes and generates #destroy /users/#{video.user_id}/videos/#{video.id}/tags/costa-rica" do
      { :delete => "/users/#{video.user_id}/videos/#{video.id}/tags/costa-rica" }.should route_to(:controller => "tags", 
                                                                                                  :action => "destroy", 
                                                                                                  :id => "costa-rica",
                                                                                                  :user_id => "#{video.user_id}",
                                                                                                  :video_id => "#{video.id}")
    end
  end
end
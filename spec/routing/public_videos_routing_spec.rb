require "spec_helper"
  
describe PublicVideosController do
  describe "routing" do
    # create a video associated with a user (by default)
    video = FactoryGirl.create(:video)
    user = test_get_object_owner(video)
    
    it "recognizes and generates #show /p/#{video.public_token}" do
      { :get => "/p/#{video.public_token}" }.should route_to(:controller => "public_videos", 
                                                             :action => "show", 
                                                             :public_token => "#{video.public_token}")
    end
    
    it "recognizes and generates #embed /embed/#{video.public_token}" do
      { :get => "/embed/#{video.public_token}" }.should route_to(:controller => "public_videos", 
                                                                 :action => "embed", 
                                                                 :public_token => "#{video.public_token}")
    end
  end
end
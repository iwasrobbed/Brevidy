require "spec_helper"
  
describe VideosController do
  describe "routing" do
    # create a video associated with a user (by default)
    video = FactoryGirl.create(:video)
    
    it "recognizes and generates #destroy /users/#{video.user_id}/videos/#{video.id}" do
      { :delete => "/users/#{video.user_id}/videos/#{video.id}" }.should route_to(:controller => "videos", 
                                                                                  :action => "destroy", 
                                                                                  :id => "#{video.id}",
                                                                                  :user_id => "#{video.user_id}")
    end
    
    it "recognizes and generates #flag /users/#{video.user_id}/videos/#{video.id}/flag" do
      { :post => "/users/#{video.user_id}/videos/#{video.id}/flag" }.should route_to(:controller => "videos", 
                                                                                     :action => "flag", 
                                                                                     :video_id => "#{video.id}",
                                                                                     :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #new /users/#{video.user_id}/videos/new" do
      { :get => "/users/#{video.user_id}/videos/new" }.should route_to(:controller => "videos",
                                                                       :action => "new",
                                                                       :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #create /users/#{video.user_id}/videos" do
      { :post => "/users/#{video.user_id}/videos" }.should route_to(:controller => "videos",
                                                                    :action => "create",
                                                                    :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #edit /users/#{video.user_id}/videos/#{video.id}/edit" do
      { :get => "/users/#{video.user_id}/videos/#{video.id}/edit" }.should route_to(:controller => "videos",
                                                                                    :action => "edit",
                                                                                    :id => "#{video.id}",
                                                                                    :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #show /users/#{video.user_id}/videos/#{video.id}" do
      { :get => "/users/#{video.user_id}/videos/#{video.id}" }.should route_to(:controller => "videos",
                                                                               :action => "show",
                                                                               :id => "#{video.id}",
                                                                               :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #update /users/#{video.user_id}/videos/#{video.id}" do
      { :put => "/users/#{video.user_id}/videos/#{video.id}" }.should route_to(:controller => "videos",
                                                                               :action => "update",
                                                                               :id => "#{video.id}",
                                                                               :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #encoder_callback /users/#{video.user_id}/videos/#{video.id}/encoder_callback" do
      { :post => "/users/#{video.user_id}/videos/#{video.id}/encoder_callback" }.should route_to(:controller => "videos",
                                                                                                 :action => "encoder_callback",
                                                                                                 :id => "#{video.id}",
                                                                                                 :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #new_video_uploaded /users/#{video.user_id}/new_video_uploaded" do
      { :put => "/users/#{video.user_id}/new_video_uploaded" }.should route_to(:controller => "videos",
                                                                               :action => "new_video_uploaded",
                                                                               :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #video_upload_error /users/#{video.user_id}/video_upload_error" do
      { :put => "/users/#{video.user_id}/video_upload_error" }.should route_to(:controller => "videos",
                                                                               :action => "upload_error",
                                                                               :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #share_dialog /users/#{video.user_id}/share_dialog" do
      { :get => "/users/#{video.user_id}/share_dialog" }.should route_to(:controller => "videos",
                                                                         :action => "share_dialog",
                                                                         :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #share_validation /users/#{video.user_id}/share_validation" do
      { :get => "/users/#{video.user_id}/share_validation" }.should route_to(:controller => "videos",
                                                                             :action => "share_validation",
                                                                             :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #share_a_link /users/#{video.user_id}/share_a_link" do
      { :get => "/users/#{video.user_id}/share_a_link" }.should route_to(:controller => "videos",
                                                                         :action => "share_a_link",
                                                                         :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #share /users/#{video.user_id}/share" do
      { :post => "/users/#{video.user_id}/share" }.should route_to(:controller => "videos",
                                                                   :action => "share",
                                                                   :user_id => "#{video.user_id}")
    end

    it "recognizes and generates #whats_happening /whats_happening" do
      { :get => "/whats_happening" }.should route_to(:controller => "videos",
                                                     :action => "whats_happening")
    end
    
    it "recognizes and generates #embed_code /users/#{video.user_id}/videos/#{video.id}/embed_code" do
      { :get => "/users/#{video.user_id}/videos/#{video.id}/embed_code" }.should route_to(:controller => "videos",
                                                                                          :action => "embed_code",
                                                                                          :user_id => "#{video.user_id}",
                                                                                          :video_id => "#{video.id}")
    end

  end
end
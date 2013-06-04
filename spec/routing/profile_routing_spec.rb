require "spec_helper"
  
describe ProfileController do
  describe "routing" do
    # create a user with an associated profile
    user = FactoryGirl.create(:user)
    
    it "recognizes and generates #index /#{user.username}/about" do
      { :get => "/#{user.username}/about" }.should route_to(:controller => "profile",
                                                            :action => "index", 
                                                            :username => "#{user.username}")
    end
    
    it "recognizes and generates #update /#{user.username}/about/update/#{user.profile.id}" do
      { :put => "/#{user.username}/about/update/#{user.profile.id}" }.should route_to(:controller => "profile", 
                                                                               :action => "update", 
                                                                               :id => "#{user.profile.id}",
                                                                               :username => "#{user.username}")
    end
  end
end
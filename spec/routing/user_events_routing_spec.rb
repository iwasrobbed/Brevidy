require "spec_helper"
  
describe UserEventsController do
  describe "routing" do
    # create a user to show/destroy
    user = FactoryGirl.create(:user)
    
    it "recognizes and generates #show /users/#{user.id}/latest_activity" do
      { :get => "/users/#{user.id}/latest_activity" }.should route_to(:controller => "user_events",
                                                                      :action => "show", 
                                                                      :user_id => "#{user.id}")
    end
    
  end
end
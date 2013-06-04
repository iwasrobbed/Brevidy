require "spec_helper"

describe InvitationLinkController do
  describe "routing" do
    user = FactoryGirl.create(:user)
    
    it "recognizes and generates #index at /#{user.username}/invitations" do
      { :get => "/#{user.username}/invitations" }.should route_to(:controller => "invitation_link", 
                                                                  :action => "index", 
                                                                  :username => "#{user.username}")
    end
    
    it "recognizes and generates #create /#{user.username}/invite_people" do
      { :post => "/#{user.username}/invite_people" }.should route_to(:controller => "invitation_link", 
                                                                     :action => "create",
                                                                     :username => "#{user.username}")
    end
    
    it "recognizes and generates users#new for /invitations/123" do
      { :get => "/invitations/123" }.should route_to(:controller => "users", 
                                                     :action => "new",
                                                     :invitation_token => "123")
    end

  end
end

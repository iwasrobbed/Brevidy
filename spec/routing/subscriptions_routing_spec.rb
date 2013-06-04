require "spec_helper"
  
describe SubscriptionsController do
  describe "routing" do
    channel = FactoryGirl.create(:channel)
    user = test_get_object_owner(channel)

    it "recognizes and generates #create /#{user.username}/channels/#{channel.id}/subscribe" do
      { :post => "/#{user.username}/channels/#{channel.id}/subscribe" }.should route_to(:controller => "subscriptions",
                                                                                        :action => "create", 
                                                                                        :username => "#{user.username}",
                                                                                        :channel_id => "#{channel.id}")
    end
    it "recognizes and generates #destroy /#{user.username}/channels/#{channel.id}/unsubscribe" do
      { :delete => "/#{user.username}/channels/#{channel.id}/unsubscribe" }.should route_to(:controller => "subscriptions",
                                                                                            :action => "destroy", 
                                                                                            :username => "#{user.username}",
                                                                                            :channel_id => "#{channel.id}")
    end
    it "recognizes and generates #subscribers /#{user.username}/subscribers" do
      { :get => "/#{user.username}/subscribers" }.should route_to(:controller => "subscriptions",
                                                                  :action => "subscribers", 
                                                                  :username => "#{user.username}")
    end
    it "recognizes and generates #subscriptions /#{user.username}/subscriptions" do
      { :get => "/#{user.username}/subscriptions" }.should route_to(:controller => "subscriptions",
                                                                    :action => "subscriptions", 
                                                                    :username => "#{user.username}")
    end
    it "recognizes and generates #remove_subscriber /#{user.username}/channels/#{channel.id}/remove_subscriber" do
      { :delete => "/#{user.username}/channels/#{channel.id}/remove_subscriber" }.should route_to(:controller => "subscriptions",
                                                                                                  :action => "remove_subscriber", 
                                                                                                  :username => "#{user.username}",
                                                                                                  :channel_id => "#{channel.id}")
    end
    it "recognizes and generates #handle_access_request /#{user.username}/channels/#{channel.id}/request_access" do
      { :get => "/#{user.username}/channels/#{channel.id}/request_access" }.should route_to(:controller => "subscriptions",
                                                                                            :action => "handle_access_request", 
                                                                                            :username => "#{user.username}",
                                                                                            :channel_id => "#{channel.id}")
    end
  end
end
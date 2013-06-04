require "spec_helper"
  
describe UsersController do
  describe "routing" do
    # create a user to show/destroy
    user = FactoryGirl.create(:user)

    it "recognizes and generates #index /users" do
      { :get => "/users" }.should route_to(:controller => "users",
                                           :action => "index")
    end
    
    it "recognizes and generates #show /users/#{user.id}" do
      { :get => "/users/#{user.id}" }.should route_to(:controller => "users",
                                                      :action => "show", 
                                                      :id => "#{user.id}")
    end
    
    it "recognizes and generates #new /users/new" do
      { :get => "/users/new" }.should route_to(:controller => "users",
                                               :action => "new")
    end
    
    it "recognizes and generates #update /users/#{user.id}" do
      { :put => "/users/#{user.id}" }.should route_to(:controller => "users",
                                                      :action => "update", 
                                                      :id => "#{user.id}")
    end
    
    it "recognizes and generates #update for /users/#{user.id}/account/update" do
      { :put => "/users/#{user.id}/account/update" }.should route_to(:controller => "users",
                                                                     :action => "update", 
                                                                     :user_id => "#{user.id}")
    end
    
    it "recognizes and generates #edit for /users/#{user.id}/account" do
      { :get => "/users/#{user.id}/account" }.should route_to(:controller => "users",
                                                              :action => "edit", 
                                                              :user_id => "#{user.id}")
    end
    
    it "recognizes and generates #update_password for /users/#{user.id}/account/password" do
      { :put => "/users/#{user.id}/account/password" }.should route_to(:controller => "users",
                                                                       :action => "update_password", 
                                                                       :user_id => "#{user.id}")
    end
    
    it "recognizes and generates #update_security_question for /users/#{user.id}/account/security_question" do
      { :put => "/users/#{user.id}/account/security_question" }.should route_to(:controller => "users",
                                                                                :action => "update_security_question", 
                                                                                :user_id => "#{user.id}")
    end
    
    it "recognizes and generates #update_birthday for /users/#{user.id}/account/birthday" do
      { :put => "/users/#{user.id}/account/birthday" }.should route_to(:controller => "users",
                                                                       :action => "update_birthday", 
                                                                       :user_id => "#{user.id}")
    end

    it "recognizes and generates #create /users" do
      { :post => "/users" }.should route_to(:controller => "users", 
                                            :action => "create")
    end
    
    it "should NOT permit destroying /users/#{user.id}" do
      { :delete => "/users/#{user.id}" }.should route_to(:controller => "errors", 
                                                         :action => "routing",
                                                         :a => "users/#{user.id}")
    end
  end
end
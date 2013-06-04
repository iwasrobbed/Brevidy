require 'spec_helper'

describe "Users" do    
  describe "GET /users" do
    describe "if the user is not currently signed in" do
      it "redirects to sign in path" do
        get users_path
        response.should redirect_to(login_path)
      end
    end
    describe "if the user is signed in" do
      it "renders the users#index page" do
        visit login_path
        integration_sign_in(FactoryGirl.create(:user))
        get users_path
        response.should render_template("users/index")
      end
    end    
  end
end

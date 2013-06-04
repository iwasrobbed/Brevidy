require 'spec_helper'

describe "FriendlyForwardings" do  
  it "should find the sign in form and login" do
    visit login_path
    integration_sign_in(FactoryGirl.create(:user))
  end
  it "should redirect the user after a successful signin" do
    user = FactoryGirl.create(:user)
    # The test automatically follows the redirect to the signin page
    visit user_path(user)
    integration_sign_in(user)
    # open the page in a browser window so we can see it
    #save_and_open_page
    # The test follows the redirect again, this time to users/show action
    response.should render_template('users/show')
  end  
end

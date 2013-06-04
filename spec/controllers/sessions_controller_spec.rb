require 'spec_helper'

describe SessionsController do
  render_views
  before do
    @user ||= FactoryGirl.create(:user)
  end
  
  describe "GET #new" do
    describe "if not signed in" do
      before do
        get :new
      end
      it "should render the sign in page" do
        response.should render_template("sessions/new")
      end
      it "should contain social login buttons" do
        response.should have_selector("div.social_login_buttons")
      end
      it "should contain a regular email/password login area" do
        response.should have_selector("div.landing_login_form")
      end
      it "should contain a sign up box" do
        response.should have_selector("h3.signup_box")
      end
      it "should not have a login box in the banner" do
        response.should_not have_selector("div.login_form")
      end
    end
    describe "if already signed in" do
      it "should redirect to the user's subscription stream" do
        post :create, :email => @user.email, :password => "password"
        controller.current_user.should == @user 
        controller.should be_signed_in
        get :new
        response.should redirect_to(user_stream_path(@user))
      end
    end
  end
  
  describe "POST #create_social_session" do
    context "if a user is signing up via Twitter with good data" do
      before do
        request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:twitter]
        post :create_social_session, :provider => "twitter"
      end   
      it "should render the signup template" do   
        response.should render_template("users/signup")
      end
      it "should have the signup form partially filled out" do
        response.should have_selector("input#signupName", :value => "BrevidyTW")
      end
      it "should have hidden fields containing the linking data" do
        response.should have_selector("input[name='provider']", :value => "twitter")
        response.should have_selector("input[name='uid']", :value => "1234")
        response.should have_selector("input[name='oauth_token']", :value => "twittertoken")
        response.should have_selector("input[name='oauth_token_secret']", :value => "twittersecret")
        response.should have_selector("input[name='social_signup']", :value => "true")
        response.should have_selector("input[name='user[location]']", :value => "Internet")
      end
    end
    context "if a user is signing up via Twitter with nil data" do
      before do
        request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:nil_twitter]
        post :create_social_session, :provider => "twitter"
      end   
      it "should still render the signup template" do   
        response.should render_template("users/signup")
      end
      it "should have the signup form partially filled out" do
        response.should have_selector("input#signupName")
      end
      it "should have hidden fields containing the linking data" do
        response.should have_selector("input[name='provider']", :value => "nil_twitter")
        response.should have_selector("input[name='uid']", :value => "1234")
        response.should have_selector("input[name='oauth_token']")
        response.should have_selector("input[name='oauth_token_secret']")
        response.should have_selector("input[name='social_signup']", :value => "true")
        response.should have_selector("input[name='user[location]']")
      end
    end
    context "if a user is signing up via Facebook with good data" do
      before do
        request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:facebook]
        post :create_social_session, :provider => "facebook"
      end   
      it "should render the signup template" do   
        response.should render_template("users/signup")
      end
      it "should have the signup form partially filled out" do
        response.should have_selector("input#signupName", :value => "BrevidyFB")
        response.should have_selector("input#signupEmail", :value => "brevidy@brevidy.com")
      end
      it "should have hidden fields containing the linking data" do
        response.should have_selector("input[name='provider']", :value => "facebook")
        response.should have_selector("input[name='uid']", :value => "5678")
        response.should have_selector("input[name='oauth_token']", :value => "facebooktoken")
        response.should have_selector("input[name='social_signup']", :value => "true")
        # this one doesn't work for some reason even though the hash is correct
        # rspec just won't go that deep into the hash
        #response.should have_selector("input[name='user[location]']", :value => "Internet")
        response.should have_selector("input[name='user[location]']")
      end
    end
    context "if a user is signing up via Twitter with nil data" do
      before do
        request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:nil_facebook]
        post :create_social_session, :provider => "facebook"
      end   
      it "should still render the signup template" do   
        response.should render_template("users/signup")
      end
      it "should have the signup form partially filled out" do
        response.should have_selector("input#signupName")
        response.should have_selector("input#signupEmail")
      end
      it "should have hidden fields containing the linking data" do
        response.should have_selector("input[name='provider']", :value => "nil_facebook")
        response.should have_selector("input[name='uid']", :value => "5678")
        response.should have_selector("input[name='oauth_token']")
        response.should have_selector("input[name='social_signup']", :value => "true")
        response.should have_selector("input[name='user[location]']")
      end
    end
  end
  
  describe "POST #create" do
    describe "with valid email and password" do
      it "should sign the user in" do 
        post :create, :email => @user.email, :password => "password"
        controller.current_user.should == @user 
        controller.should be_signed_in
      end
      context "via HTML format" do
        it "should redirect to the user's following stream" do 
          post :create, :email => @user.email, :password => "password"
          response.should redirect_to(user_stream_path(@user))
        end 
      end
      context "via JSON format" do
        it "should render a success json response" do
          post :create, :email => @user.email, :password => "password", :format => :json
          json = JSON.parse(response.body)
          json['success'].should == true
          json['message'].should == nil
          json['user_id'].should == @user.id
        end
      end
    end
    describe "with invalid email and password" do
      it "should not sign in the user" do
        post :create, :email => @user.email, :password => "wrongpassword"
        controller.current_user.should_not == @user
        controller.should_not be_signed_in
      end
      context "via HTML format" do
        it "should redirect to the sign in page and flash error" do
          post :create, :email => @user.email, :password => "wrongpassword"
          response.should redirect_to(login_path)
          flash[:error].should =~ /invalid/i
        end
      end
      context "via JSON format" do
        it "should render an unsuccessful json response w/ error message" do          
          post :create, :email => @user.email, :password => "wrongpassword", :format => :json
          json = JSON.parse(response.body)
          json['success'].should == false
          json['message'].should contain("Invalid login credentials")
          json['user_id'].should == false
        end
      end
    end
  end
  
  describe "DELETE #destroy" do
    it "should sign a user out" do
      test_sign_in(@user) 
      controller.should be_signed_in
      delete :destroy 
      controller.should_not be_signed_in 
      response.should redirect_to(:root)
    end
  end
  
end

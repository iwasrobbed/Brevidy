require 'spec_helper'
include ActionView::Helpers::TextHelper
include ActionView::Helpers::UrlHelper

describe ProfileController do
  render_views
  
  before do
    @user ||= FactoryGirl.create(:user)
    @userB ||= FactoryGirl.create(:user)
    @profile = @user.profile
    @profileB = @userB.profile
    test_sign_in(@user)
  end
  
=begin
  describe "GET #index" do
    it "should be successful" do
      get :index, :user_id => @user.id
      response.should be_success
      response.should render_template("profile/index")
    end
    describe "if the user is blocked by or has blocked another user" do
      before do
        @userB.block!(@user)
      end
      it "should say the user can't be found or the user doesn't have permission to view them" do
        get :index, :user_id => @userB
        response.should render_template('errors/error_404')
      end
    end
  end
  
  describe "PUT #update" do
    describe "for an invalid request" do
      it "should return an error via JSON" do
        xhr :put, :update, :user_id => @user.id, :id => @profile.id, :profile => nil 
        json = JSON.parse(response.body)
        response.status.should == unprocessable_entity
        json['error'].should_not be_nil
        json['error'].should contain("There was no profile data passed in")
      end
    end
    describe "for a valid request" do
      before do
        xhr :put, :update, :user_id => @user.id, :id => @profile.id, :profile => { :interests => "Brevidy <script>Oh hai!</script>" }
        @json = JSON.parse(response.body)
      end
      it "should be successful" do
         response.status.should == accepted
      end
      it "should update the profile attribute" do
        @profile.interests.should contain("Brevidy")
      end
      it "should render the attribute back as sanitized, formatted HTML" do
        @json['html']['interests'].should_not be_nil
        @json['html']['interests'].should have_selector('p.pbs.tl')
      end
    end
  end
=end
end
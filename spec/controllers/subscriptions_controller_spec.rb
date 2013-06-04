require 'spec_helper'
include DelayedJobSpecHelper 

describe SubscriptionsController do
  render_views
  
  before do
    @user ||= test_sign_in(FactoryGirl.create(:user, :name => "The Follower"))
    @followed ||= FactoryGirl.create(:user)
    # clear out old mail
    ActionMailer::Base.deliveries = []
  end
  
=begin
  describe "accessible attributes" do
    before do
      @user.follow!(@followed)
      @subscription ||= Subscription.where(:follower_id => @user.id, :followed_id => @followed.id).first
    end
    it "should NOT allow mass-assignment of non-accessible attributes" do
      @subscription.should_not allow_mass_assignment_of(:id => "999999")
      @subscription.should_not allow_mass_assignment_of(:follower_id => "999999")
      @subscription.should_not allow_mass_assignment_of(:created_at => "999999")
      @subscription.should_not allow_mass_assignment_of(:updated_at => "999999")
    end
    it "should allow mass-assignment of accessible attributes" do
      @subscription.should allow_mass_assignment_of(:followed_id => "999999")
    end
  end
  
  describe "POST #create" do    
    describe "for a valid request" do
      it "should create a subscription with AJAX" do
        lambda do
          xhr :post, :create, :user_id => @followed
          response.status.should == created
        end.should change(Subscription, :count).by(1)
      end
      it "should render an unfollow button back via JSON" do
        xhr :post, :create, :user_id => @followed
        response.status.should == created
        json = JSON.parse(response.body)
        json['unfollow_button'].should_not be_nil
        json['unfollow_button'].should have_selector('a.removeFollower', :content => 'Unfollow')
      end
      it "should send the person being followed an email only if their notification settings say to do so" do
        setting = @followed.setting
        setting.send_email_for_new_follower = true
        setting.save
        
        xhr :post, :create, :user_id => @followed
        
        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs
          
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent['to'].to_s.should == @followed.email
        last_email_sent['subject'].to_s.should contain("#{@user.name} started following you on Brevidy")
        
        # now destroy the subscription and try again
        # with the notification turned off
        @user.unfollow!(@followed)
        
        # clear out old mail
        ActionMailer::Base.deliveries = []
    
        setting.send_email_for_new_follower = false
        setting.save
        
        xhr :post, :create, :user_id => @followed
        
        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs
          
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent.should be_nil
      end
    end
    
    describe "for event creation" do
      it "should create a new event object for User B if User A starts following User B" do
        xhr :post, :create, :user_id => @followed
        
        subscription = Subscription.last

        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs
     
        UserEvent.where(:event_type => UserEvent.event_type_value(:subscription), 
                        :event_object_id => subscription.id,
                        :user_id => @followed.id,
                        :event_creator_id => @user.id).should exist
      end
    end
    
    describe "for an invalid request" do
      it "should not let the user follow themselves" do
        xhr :post, :create, :user_id => @user
        response.status.should == unauthorized
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain('You cannot follow yourself')
      end
      it "should not let the user follow someone more than once" do
        xhr :post, :create, :user_id => @followed
        response.status.should == created
        xhr :post, :create, :user_id => @followed
        response.status.should == unprocessable_entity
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain('You are already following this user')
      end
      it "should render a 404 error if no associated user was found" do
        # give it a bad user ID
        xhr :post, :create, :user_id => "999999"
        response.status.should == not_found
      end
      it "should not let the user follow someone they are blocking" do
        @user.block!(@followed)
        xhr :post, :create, :user_id => @followed
        response.should render_template("errors/error_404")
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @user.follow!(@followed)
    end
    
    describe "for a valid request" do
      it "should destroy a subscription via AJAX" do
        lambda do
          xhr :delete, :destroy, :user_id => @followed
          response.status.should == ok
        end.should change(Subscription, :count).by(-1)
      end
      it "should render a follow button back via JSON" do
        xhr :delete, :destroy, :user_id => @followed
        response.status.should == ok
        json = JSON.parse(response.body)
        json['follow_button'].should_not be_nil
        json['follow_button'].should have_selector('a.addFollower', :content => 'Follow')
      end
    end
    
    describe "for event deletion" do
      it "should remove the event object for User B if User A unfollows User B" do
        @user.unfollow!(@followed)
        # follow them through the controller
        xhr :post, :create, :user_id => @followed
        
        @subscription = Subscription.last
      
        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs
        
        user_event = UserEvent.where(:event_type => UserEvent.event_type_value(:subscription), 
                                     :event_object_id => @subscription.id,
                                     :user_id => @followed.id,
                                     :event_creator_id => @user.id)
        user_event.should exist
        
        xhr :delete, :destroy, :user_id => @followed
        
        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs
     
        user_event.should_not exist
      end
    end
    
    describe "for an invalid request" do
      it "should render a 404 error if no subscription was found involving that user" do
        # create a user that we haven't followed yet
        @other_user = FactoryGirl.create(:user)
        # now try to unfollow them
        xhr :delete, :destroy, :user_id => @other_user
        response.status.should == not_found
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain('You are currently not following this user')
      end
      it "should render a 404 error if no associated user was found" do
        # give it a bad user ID
        xhr :delete, :destroy, :user_id => "999999"
        response.status.should == not_found
      end
    end
  end
  
  describe "POST #block" do
    describe "for a valid request" do
      before do
        @user.follow!(@followed)
        @followed.follow!(@user)
      end
      it "should be successful" do
        xhr :post, :block, :user_id => @followed
        response.status.should == created
      end
      it "should destroy any prior following/follower subscriptions that user may have with the other person" do
        lambda do
          xhr :post, :block, :user_id => @followed
        end.should change(Subscription, :count).by(-2)
        regular_subscription = Subscription.where(:followed_id => @user.id, :follower_id => @followed.id).first
        reverse_subscription = Subscription.where(:follower_id => @user.id, :followed_id => @followed.id).first
        regular_subscription.should be_nil
        reverse_subscription.should be_nil
      end
      it "should create a new blocking record" do
        lambda do
          xhr :post, :block, :user_id => @followed
        end.should change(Blocking, :count).by(1)
        blocking = Blocking.where(:requesting_user => @user.id, :blocked_user => @followed.id).first
        blocking.should_not be_nil
      end
    end
    describe "for an invalid request" do
      it "should not let a user block someone more than once without first unblocking them" do
        xhr :post, :block, :user_id => @followed
        response.status.should == created
        xhr :post, :block, :user_id => @followed
        response.status.should == unprocessable_entity
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain('You are already blocking that user')
      end
      it "should render a 404 error if no associated user was found" do
        # give it a bad user ID
        xhr :post, :block, :user_id => "999999"
        response.status.should == not_found
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain('That user does not exist so we were unable to block them')
      end
    end
  end
  
  describe "POST #unblock" do
    describe "for a valid request" do
      before do
        @user.follow!(@followed)
        @followed.follow!(@user)
        @user.block!(@followed)
      end
      it "should be successful" do
        xhr :post, :unblock, :user_id => @followed
        response.status.should == ok
      end
      it "should find and destroy the blocking record" do
        lambda do
          xhr :post, :unblock, :user_id => @followed
        end.should change(Blocking, :count).by(-1)
        blocking = Blocking.where(:requesting_user => @user.id, :blocked_user => @followed.id).first
        blocking.should be_nil
      end
    end
    describe "for an invalid request" do
      it "should not let a user unblock someone more than once without first blocking them again" do
        @user.block!(@followed)
        xhr :post, :unblock, :user_id => @followed
        response.status.should == ok
        xhr :post, :unblock, :user_id => @followed
        response.status.should == unprocessable_entity
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain('You are not currently blocking that user')
      end
      it "should render a 404 error if no associated user was found" do
        # give it a bad user ID
        xhr :post, :unblock, :user_id => "999999"
        response.status.should == not_found
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain('That user does not exist so we were unable to unblock them')
      end
    end
  end
  
  describe "GET #followers" do
    before do
      @other_user = FactoryGirl.create(:user)
      @followed.follow!(@other_user)
    end
    it "should be successful" do
      get :followers, :user_id => @other_user
      response.should be_success
      response.should render_template('subscriptions/followers')
    end
    it "should render more followers if accessed via AJAX" do
      xhr :get, :followers, :user_id => @other_user
      response.should be_success
      response.should render_template('subscriptions/followers')
    end
    it "should show the correct number of followers" do
      get :followers, :user_id => @other_user
      response.should contain('Followers (1)')
    end
    it "should have a link to the @other_user in the list of followers" do
      get :followers, :user_id => @other_user
      response.should have_selector('div.followListMeta a', :href => user_path(@followed))
    end
    
    describe "after the current_user has blocked someone" do
      before do
        # we haved created a different user, and had @followed follow that other user
        # now view @other_user's followers and see if @followed shows up in it
        # if the current_user has blocked @followed
        @user.block!(@followed)
        get :followers, :user_id => @other_user
      end
      it "should not contain any users that the current user has blocked" do
        response.should contain('This person does not currently have any followers')
      end
      it "should have the correct count for only what the current user can see" do
        response.should contain('Followers (0)')
      end
      it "should not contain any blocked users in the My Stuff header" do
        response.should_not have_selector('div.followPhotos a', :href => user_path(@followed))
      end
      it "should say the user can't be found or the user doesn't have permission to view them" do
        get :followers, :user_id => @followed
        response.should render_template('errors/error_404')
      end
    end
  end
  
  describe "GET #following" do
    before do
      @other_user = FactoryGirl.create(:user)
      @other_user.follow!(@followed)
    end
    it "should be successful" do
      get :following, :user_id => @other_user
      response.should be_success
      response.should render_template('subscriptions/following')
    end
    it "should render more following if accessed via AJAX" do
      xhr :get, :following, :user_id => @other_user
      response.should be_success
      response.should render_template('subscriptions/following')
    end
    it "should show the correct number of following" do
      get :following, :user_id => @other_user
      response.should contain('Following (1)')
    end
    it "should have a link to the @other_user in the list of following" do
      get :following, :user_id => @other_user
      response.should have_selector('div.followListMeta a', :href => user_path(@followed))
    end

    describe "after the current_user has blocked someone" do
      before do
        # we haved created a different user, and had @followed follow that other user
        # now view @other_user's following and see if @followed shows up in it
        # if the current_user has blocked @followed
        @user.block!(@followed)
        get :following, :user_id => @other_user
      end
      it "should not contain any users that the current user has blocked" do
        response.should contain('This person does not have a following yet')
      end
      it "should have the correct count for only what the current user can see" do
        response.should contain('Following (0)')
      end
      it "should not contain any blocked users in the My Stuff header" do
        response.should_not have_selector('div.followPhotos a', :href => user_path(@followed))
      end
      it "should say the user can't be found or the user doesn't have permission to view them" do
        get :following, :user_id => @followed
        response.should render_template('errors/error_404')
      end
    end
  end
=end
end
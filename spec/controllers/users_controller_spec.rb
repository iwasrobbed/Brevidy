require 'spec_helper'
include DelayedJobSpecHelper 
  
describe UsersController do
  render_views
  
=begin
  describe "authentication of actions" do
    before do 
      @user ||= FactoryGirl.create(:user)
    end 
    
    describe "for non-signed-in users" do
      it "should deny access to #index" do
        get :index, :id => @user
        response.should redirect_to(:login)
      end
      it "should deny access to #show" do
        get :show, :id => @user
        response.should redirect_to(:login)
      end
      it "should deny access to #edit" do 
        get :edit, :user_id => @user 
        response.should redirect_to(:login)
      end
      it "should deny access to #update" do 
        put :update, :id => @user, :user => {} 
        response.should redirect_to(:login)
      end 
      it "should deny access to #update_password" do 
        put :update_password, :user_id => @user, :user => {} 
        response.should redirect_to(:login)
      end
      it "should deny access to #update_birthday" do 
        put :update_birthday, :user_id => @user, :user => {} 
        response.should redirect_to(:login)
      end
      it "should NOT deny access to #forgotten_password" do
        get :forgotten_password, :id => @user
        response.should be_success
        response.should render_template("users/forgotten_password")
      end
      it "should NOT deny access to #reset_password" do
        # generate a reset password token
        get :forgotten_password, :email => @user.email
        get :reset_password, :user_id => @user, :token => @user.reset_token
        response.should be_success
        response.should render_template("users/forgotten_password")
      end
    end
    
    describe "for signed-in users" do
      describe "who are naughty" do
        before do
          # login as User B
          @wrong_user = FactoryGirl.create(:user, :email => "wrong_user@brevidy.com")
          test_sign_in(@wrong_user)
        end
        # try to access the edit action for User A
        it "should require matching users for #edit action" do
          get :edit, :user_id => @user
          response.should render_template('errors/error_404')
        end
        # try to access the update action for User A
        it "should require matching users for #update action" do
          put :update, :id => @user, :user => {}
          response.should render_template('errors/error_404')
        end
        # try to access the update password action for User A
        it "should require matching users for #update_password action" do
          put :update_password, :user_id => @user, :user => {}
          response.should render_template('errors/error_404')
        end
        # try to access the update birthday action for User A
        it "should require matching users for #update_birthday action" do
          put :update_birthday, :user_id => @user, :user => {}
          response.should render_template('errors/error_404')
        end
      end
    end
  end
  
  describe "GET #signup" do
    context "if the user is logged in" do
      it "should redirect you if you're already logged in" do
        @user ||= FactoryGirl.create(:user)
        test_sign_in(@user)
      
        get :signup
        response.should redirect_to(user_stream_path(@user))
      end
    end
    context "if the user is logged out" do
      before do
        get :signup
      end
      it "should contain an old fashioned signup form area" do
        response.should contain("Sign up the old fashioned way")
        response.should have_selector('.old_fashioned_signup')
        response.should have_selector('#signupName')
        response.should have_selector('#signupEmail')
        response.should have_selector('#signupPassword')
        response.should have_selector('#signupBirthdayMonth')
        response.should have_selector('#signupBirthdayDay')
        response.should have_selector('#signupBirthdayYear')
        response.should have_selector('input.signup.button')
      end
      it "should contain social signup buttons" do
        response.should contain("Quick Sign up")
        response.should have_selector('div.social_signup_buttons')
      end
      it "should have a login button at the top in case they already have an account" do
        response.should have_selector("div.login_form")
        response.should contain("Already a member? Login!")
      end
      it "should have a disclaimer for agreeing to our ToS" do
        response.should contain("By clicking Sign up, you are indicating that you have read and agree to the terms of service")
      end
    end
  end
  
  describe "GET #new (this tests signup_via_invitation route also) " do
    before do
      @user ||= FactoryGirl.create(:user)
    end
    describe "if signed in" do
      it "should redirect the user to their following stream" do
        test_sign_in(@user)
        get :new
        response.should redirect_to(user_stream_path(@user))
      end
    end
    describe "if not signed in" do
      describe "using a valid invitation token" do
        before do
          @invitation = InvitationLink.create(:email_asking_for_invite => "new_user@brevidy.com")
          @invitation.invitation_limit.should == 1
          get :new, :invitation_token => @invitation.token
        end
        it "should be successful" do
          response.should be_success 
        end
        it "should have welcome message" do
          response.should contain('Share the fleeting moments of your life on video')
          response.should contain('Connect with people around you')
          response.should contain('Let others join in the fun')
        end
        it "should contain social signup buttons and a regular signup link" do
          response.should have_selector('.social_buttons')
          response.should have_selector('.old_fashioned')
        end
        it "should contain login button" do
          response.should have_selector('.login_form')
        end
        it "should increment the click count" do
          @invitation.reload
          @invitation.click_count.should == 1
        end
      end
      describe "using an invalid invitation token" do
        it "should render the page anyways" do
          get :new, :invitation_token => 'invalid token'
          response.should render_template('users/new')
        end
      end
    end
  end

  
  describe "GET #forgotten_password" do
    describe "if signed in" do
      it "should redirect them to their stream" do
        @user = FactoryGirl.create(:user)
        test_sign_in(@user)
        get :forgotten_password 
        response.should redirect_to(user_path(@user))
      end
    end
    describe "if not signed in" do
      before do
        get :forgotten_password 
      end
      it "should be successful" do
        response.should be_success
      end
      it "should have an email field" do
        response.should have_selector('div.forgotten_password_form input#email')
      end
      it "should have a submit button" do
        response.should have_selector('div.forgotten_password_form input.silver.button')
      end
      it "should show an optional signup area" do
        response.should have_selector('div.landing_signup')
      end
    end
  end
  
  describe "POST #forgotten_password" do
    before do
      # clear out old mail
      ActionMailer::Base.deliveries = []
      
      @user = FactoryGirl.create(:user)
      post :forgotten_password, :email => @user.email
      # for some reason, it grabs @user from cache so 
      # we have to set it explicitly like so to get the new 
      # reset token and expiration date, otherwise they end up being nil again
      @user = User.find_by_email(@user.email)
    end
    it "should be successful" do
      response.should be_success
    end
    it "should contain a vague success message" do
      response.should contain("we will send password reset instructions shortly") 
    end
    it "should create a reset password token" do
      @user.reset_token.should_not be_nil
    end
    it "should set today's date as the pw_reset_timestamp for token expiration" do
      date_then = Date.new(@user.pw_reset_timestamp.year, @user.pw_reset_timestamp.month, @user.pw_reset_timestamp.day)
      date_then.should == Date.today
    end
    it "should email password reset instructions to a valid user" do
      # complete all delayed_job tasks such as sending mail
      test_complete_all_jobs
          
      last_email_sent = ActionMailer::Base.deliveries.last
      last_email_sent['to'].to_s.should == @user.email
      last_email_sent['subject'].to_s.should contain("Reset password instructions")
    end
  end
  
  describe "GET #reset_password" do
    before do
      @user = FactoryGirl.create(:user)
      # generate a reset password token for User A
      post :forgotten_password, :email => @user.email
      @user = User.find_by_email(@user.email)
      @pw_reset_invalid_msg = /The reset password link you are attempting to use is invalid or has expired/i
    end
    describe "if signed in" do
      it "should redirect them to their stream" do
        test_sign_in(@user)
        get :reset_password, :user_id => @user, :token => @user.reset_token
        response.should redirect_to(user_path(@user))
      end
    end
    describe "if not signed in" do
      describe "for an invalid request" do
        it "should show a header telling them to enter their email" do
          response.should contain("Please enter your email address below")
        end
        it "should require reset password token matches the user ID passed in" do
          # create User B
          @wrong_user = FactoryGirl.create(:user, :email => "wrong_user@brevidy.com")
          # try to use it as User B
          get :reset_password, :user_id => @wrong_user, :token => @user.reset_token
          flash.now[:error].should =~ @pw_reset_invalid_msg
        end
        it "should ensure the token is no older than 2 days" do
          @user.pw_reset_timestamp = 5.days.ago
          @user.save
          get :reset_password, :user_id => @user, :token => @user.reset_token
          flash.now[:error].should =~ @pw_reset_invalid_msg
        end
        it "should show an optional signup area" do
          response.should have_selector('div.landing_signup')
        end
      end
      describe "for a valid request" do
        before do
          get :reset_password, :user_id => @user, :token => @user.reset_token
        end
        it "should be successful" do
          response.should be_success
        end
        it "should show a header telling them to reset their password" do
          response.should contain("Please reset your password below")
        end
        it "should show password reset fields" do
          response.should have_selector('div.forgotten_password_form input#password')
          response.should have_selector('div.forgotten_password_form input#password_confirmation')
        end
        it "should show an optional signup area" do
          response.should have_selector('div.landing_signup')
        end
      end
    end
  end

  describe "POST #reset_password" do
    before do
      @user = FactoryGirl.create(:user)
      # generate a reset password token for user
      post :forgotten_password, :email => @user.email
      @user = User.find_by_email(@user.email)
    end
    describe "for a valid request" do
      before do
        post :reset_password,
             :user_id => @user,
             :password => "password", 
             :password_confirmation => "password",
             :token => @user.reset_token
      end
      it "should redirect the user to their stream" do
        response.should redirect_to(user_path(@user))
      end
      it "should show a success message" do
        flash[:success].should =~ /Your password was successfully reset/i
      end
    end
    describe "for an invalid request" do
      it "should verify the passwords match" do
        # give it non-matching passwords
        post :reset_password,
             :user_id => @user,
             :password => "password", 
             :password_confirmation => "not a matching password",
             :token => @user.reset_token
        flash.now[:error].should =~ /Passwords do not match/i
      end
      it "should not let someone else reset User A's password without guessing User A's token" do
        # give it a bad token
        post :reset_password,
             :user_id => @user,
             :password => "password", 
             :password_confirmation => "password",
             :token => "bad token"
        flash.now[:error].should =~ /The reset password link you are attempting to use is invalid or has expired/i
      end 
    end
  end
  
  describe "POST #create" do
    before do
      @user ||= FactoryGirl.build(:user, :name => "User A", :email => "some_new_user@brevidy.com") 
      # invite the user by a pre-existing user
      @userB ||= FactoryGirl.create(:user, :name => "User B")
      @invitation ||= @userB.invitation_link
      # for some reason you can't pass in @user
      @attr ||= { :name => @user.name, :email => @user.email,
                  :password => @user.password, :birthday => @user.birthday }
                 
      # set the cookie
      request.cookies['invitation_token'] = "#{@invitation.token}"
         
      # clear out old mail
      ActionMailer::Base.deliveries = []
    end 
    describe "failure" do
      # pass it a nil hash
      it "should not create a user" do
        lambda do
          post :create, :user => nil, :format => :js
        end.should_not change(User, :count)
      end
      context "via JS format" do
        it "should return errors" do
          # it will return all errors, so just use one of the
          # validation error messages to check this
          post :create, :user => nil, :format => :js
          response.should contain(".formErrorField.js-validate")
          response.should contain("Name contains invalid characters")
        end
      end
      context "via JSON format" do
        it "should return errors" do
          post :create, :user => nil, :format => :json
          json = JSON.parse(response.body)
          json['success'].should == false
          json['message'].should contain("Name contains invalid characters")
          json['user_id'].should == false
        end
      end
    end
    describe "success" do
      context "via HTML format" do
        it "should redirect them to their following stream" do
          pending "need to figure out how to check redirects via XHR requests"
        end
      end
      context "via JSON format" do
        it "should return an appropriate JSON response" do
          post :create, :user => @attr, :format => :json
          json = JSON.parse(response.body)
          json['success'].should == true
          json['message'].should == nil
          json['user_id'].should == User.find_by_email("some_new_user@brevidy.com").id
        end
      end
      it "should create a user" do
        lambda do
          post :create, :user => @attr, :format => 'js'
        end.should change(User, :count).by(1)
      end
      it "should sign the user in" do
        post :create, :user => @attr, :format => 'js'
        controller.should be_signed_in
      end
      it "should find if someone invited them and create a two-way relationship" do
        # see if the correct relationships were formed
        post :create, :user => @attr, :format => 'js'
        user = User.find_by_email(@user.email)
        Subscription.where(:followed_id => @userB.id, :follower_id => user.id).should exist
        Subscription.where(:followed_id => user.id, :follower_id => @userB.id).should exist
      end
      it "should send an e-mail to each person in the two-way relationship telling them about their new follower if the notification settings say to do so" do
        # clear out old mail
        ActionMailer::Base.deliveries = []
      
        settingB = @userB.setting
        settingB.send_email_for_new_follower = true
        settingB.save
      
        # see if emails were sent
        post :create, :user => @attr, :format => 'js'
        user = User.find_by_email(@user.email)
        
        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs
        
        last_email_sent = ActionMailer::Base.deliveries[0]
        last_email_sent['subject'].should contain("#{@userB.name} started following you on Brevidy")
        last_email_sent['to'].should contain("#{@user.email}")
        
        last_email_sent = ActionMailer::Base.deliveries[1]
        last_email_sent['subject'].should contain("#{@user.name} started following you on Brevidy")
        last_email_sent['to'].should contain("#{@userB.email}")
      end
      it "should NOT send an email to @userB if their notifications say not to do so" do
        # clear out old mail
        ActionMailer::Base.deliveries = []
      
        settingB = @userB.setting
        settingB.send_email_for_new_follower = false
        settingB.save
      
        # see if emails were sent
        post :create, :user => @attr, :format => 'js'
        user = User.find_by_email(@user.email)
        
        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs
        
        last_email_sent = ActionMailer::Base.deliveries[0]
        last_email_sent['subject'].should contain("#{@userB.name} started following you on Brevidy")
        last_email_sent['to'].should contain("#{@user.email}")
        
        last_email_sent = ActionMailer::Base.deliveries
        last_email_sent.each do |e|
          e['subject'].should_not contain("#{@user.name} started following you on Brevidy")
          e['to'].should_not contain("#{@userB.email}")
        end
      end
    end
  end

  describe "GET #index if signed in" do
    before do
      @test_image = "http://brevidyassets.s3.amazonaws.com/images/default_user_150px.jpg"
      @user ||= FactoryGirl.create(:user, :name => "Billy Bob Joe")
      @user.remote_image_url = @test_image
      @user.save
      @userC ||= FactoryGirl.create(:user)
      @userC.remote_image_url = @test_image
      @userC.save
     
      test_sign_in(@user)
    end
    describe "for valid requests" do
      describe "made via the browser" do
        before do
          get :index
        end
        it "should be successful" do
          response.should render_template('users/index')
        end
        it "should show other users" do
          response.should have_selector('li.infiniteScrollingItem')
          response.should have_selector('h3', :content => @userC.name)
        end
        it "should show yourself" do
          response.should have_selector('h3', :content => @user.name)
        end
      end
    end
    describe "if the user has blocked someone or been blocked by someone" do
      before do
        @userB ||= FactoryGirl.create(:user, :name => "Blocked User Name")
        @userB.remote_image_url = @test_image
        @userB.save
        @user.block!(@userB)
      end
      it "should not show blocked users" do
        get :index
        response.should_not contain("Blocked User Name")
      end
    end
  end
  
  describe "GET #show if signed in" do
    before do
      # create and sign in User A
      @user = FactoryGirl.create(:user)
      test_sign_in(@user)
      # create User B for viewing / interaction
      @userB = FactoryGirl.create(:user)
      @userB.follow!(@user)
    end
    describe "if the current user is not blocked" do
      describe "and the call is made via the browser" do
        before do
          get :show, :id => @userB
        end
        it "should show the requested user" do
          response.should render_template("users/show")
        end
        it "should have the requested user's name in the page" do 
          response.should have_selector('h2.name', :content => @userB.name)
        end
        it "should have the requested user's name in the title" do
          response.should have_selector('title', :content => @userB.name)
        end
        it "should have the correct follower/following counts" do
          response.should have_selector("a", :href => user_subscriptions_path(@userB),
                                             :content => "Following (1)")
          response.should have_selector("a", :href => user_subscribers_path(@userB),
                                            :content => "Followers (0)")                                   
        end
      end
      describe "and the call is made via AJAX" do
        it "should only render the video fragments for the next page" do
          # create enough videos to reach 2nd page
          20.times { FactoryGirl.create(:video, :user_id => @userB.id) }
          
          # now get the 2nd page
          xhr :get, :show, :id => @userB, :page => 2, :format => :js
          response.should render_template("users/show")
          # check to make sure it doesn't have a page title element
          # so we know it's only a fragment
          response.should_not have_selector('title')
        end
      end
    end
    describe "if the current user is blocked by or has blocked someone" do
      before do
        @user.block!(@userB)
      end
      it "should say the user can't be found or the user doesn't have permission to view them" do
        get :show, :id => @userB
        response.should render_template('errors/error_404')
      end
    end
    describe "if the current user is deactivated" do
      it "should tell the user they were deactivated" do
        @user.is_deactivated = true
        @user.save
        
        get :show, :id => @user
        response.should render_template('errors/error_deactivated')
      end
    end
  end
  
  describe "GET #followers_stream" do
    before do
      # create and sign in User A
      @user = FactoryGirl.create(:user)
      test_sign_in(@user)
      # create User B for viewing / interaction
      @userB = FactoryGirl.create(:user)
    end
    describe "if the current user is blocked by or has blocked user B" do
      before do
        @user.block!(@userB)
      end
      it "should say the user can't be found or the user doesn't have permission to view them" do
        get :followers_stream, :user_id => @userB
        response.should render_template('errors/error_404')
      end
    end
    describe "for blocked videos in the stream" do
      before do
        @videoC ||= FactoryGirl.create(:video)
        @userC ||= test_get_object_owner(@videoC)
        @userC.follow!(@userB)
        @user.block!(@userC)
      end
      it "should not show them to the user" do
        get :followers_stream, :user_id => @userB
        response.should contain("There are currently no videos to show")
      end
    end
  end
  
  describe "GET #following_stream" do
    before do
      # create and sign in User A
      @user = FactoryGirl.create(:user)
      test_sign_in(@user)
      # create User B for viewing / interaction
      @userB = FactoryGirl.create(:user)
    end
    describe "if the current user is blocked by or has blocked user B" do
      before do
        @user.block!(@userB)
      end
      it "should say the user can't be found or the user doesn't have permission to view them" do
        get :following_stream, :user_id => @userB
        response.should render_template('errors/error_404')
      end
    end
    describe "for blocked videos in the stream" do
      before do
        @videoC ||= FactoryGirl.create(:video)
        @userC ||= test_get_object_owner(@videoC)
        @userB.follow!(@userC)
        @user.block!(@userC)
      end
      it "should not show them to the user" do
        get :following_stream, :user_id => @userB
        response.should contain("There are currently no videos to show")
      end
    end
  end

  describe "GET #edit" do
    before do
      @user = FactoryGirl.create(:user)
      test_sign_in(@user)
    end
    it "should show the user's account page" do
      get :edit, :user_id => @user
      response.should render_template('users/edit')
    end
    it "should show any blocked users" do
      @userB ||= FactoryGirl.create(:user, :name => "Blocked User Name")
      @user.block!(@userB)
      
      get :edit, :user_id => @user
      response.should contain(@userB.name)
      response.should contain("(unblock)")
    end
  end
  
  describe "PUT #update" do
    before do
      @user = FactoryGirl.create(:user)
      test_sign_in(@user)
    end
    describe "for a valid request" do
      it "should be successful" do
        xhr :put, :update, :user_id => @user.id, :user => { :name => "Poop" }, :format => 'js'
        response.status.should == accepted
        @user.name.should contain("Poop") 
      end
      it "should let the user update an attribute that is accessible" do
        @user.should allow_mass_assignment_of(:email => "user@brevidy.com")
        @user.should allow_mass_assignment_of(:password => "password")
        @user.should allow_mass_assignment_of(:name => "Test")
        @user.should allow_mass_assignment_of(:birthday => "1990-1-1")
        @user.should allow_mass_assignment_of(:gender => "Female") 
        @user.should allow_mass_assignment_of(:location => "Somewhere")
        @user.should allow_mass_assignment_of(:security_question => "Some question")
        @user.should allow_mass_assignment_of(:security_answer => "Some answer")
      end
    end
    describe "for an invalid request" do
      it "should not let the user mass-assign any non-accessible attributes" do
        @user.should_not allow_mass_assignment_of(:id => 1)
        @user.should_not allow_mass_assignment_of(:salt => 1)
        @user.should_not allow_mass_assignment_of(:created_at => 1)
        @user.should_not allow_mass_assignment_of(:updated_at => 1)
        @user.should_not allow_mass_assignment_of(:is_deactivated => true)
        @user.should_not allow_mass_assignment_of(:reset_token => 1)
        @user.should_not allow_mass_assignment_of(:pw_reset_timestamp => 1)
      end
    end
  end

  describe "PUT #update_password" do
    before do
      @user = FactoryGirl.create(:user)
      test_sign_in(@user)
    end
    describe "for a valid request" do
      it "should be successful" do
        xhr :put, :update_password, :user_id => @user.id, 
                  :old_password => 'password',
                  :new_password => 'new_password',
                  :confirm_new_password => 'new_password',
                  :format => 'js'
        response.status.should == accepted
        # for whatever reason, the @user object is stale
        # so we have to do this 
        new_user = User.find_by_email(@user.email)
        new_user.has_password?('new_password').should be_true
      end
    end
    describe "for an invalid request" do
      it "should ensure the old password matches before letting them change their password" do
        # give it the wrong password
        xhr :put, :update_password, :user_id => @user.id, 
                  :old_password => 'wrong_password',
                  :new_password => 'new_password',
                  :confirm_new_password => 'new_password',
                  :format => 'js'
        json = JSON.parse(response.body)
        json['error'].should contain('Your old password does not match the password we have on record')
      end
      it "should ensure the new password and the confirmation passwords match" do
        # give it the wrong confirmation password
        xhr :put, :update_password, :user_id => @user.id, 
                  :old_password => 'password',
                  :new_password => 'new_password',
                  :confirm_new_password => 'wrong_confirmation_password',
                  :format => 'js'
        json = JSON.parse(response.body)
        json['error'].should contain('Your new password does not match the confirmation password')
      end
    end
  end
  
  describe "PUT #update_security_question" do
    before do
      @user = FactoryGirl.create(:user)
      test_sign_in(@user)
    end
    describe "for a valid request" do
      it "should be successful" do
        xhr :put, :update_security_question, :user_id => @user.id, 
                  :security_question => 'Some question',
                  :security_answer => 'Some answer',
                  :format => 'js'
        response.status.should == accepted
        # for whatever reason, the @user object is stale
        # so we have to do this 
        new_user = User.find_by_email(@user.email)
        new_user.security_question.should contain("Some question")
        new_user.security_answer.should contain("Some answer")
      end
    end
    describe "for an invalid request" do
      it "should ensure the both the security question and answer are not blank" do
        # give it a blank question
        xhr :put, :update_security_question, :user_id => @user.id, 
                  :security_question => nil,
                  :security_answer => 'Some answer',
                  :format => 'js'
                  
        response.status.should == unprocessable_entity
        json = JSON.parse(response.body)
        json['error'].should contain('Check they are not blank')
        
        # give it a blank answer
        xhr :put, :update_security_question, :user_id => @user.id, 
                  :security_question => 'Some question',
                  :security_answer => nil,
                  :format => 'js'
        
        response.status.should == unprocessable_entity
        json = JSON.parse(response.body)
        json['error'].should contain('Check they are not blank')
      end
      it "should ensure the security question has not already been set" do
        # set it once
        xhr :put, :update_security_question, :user_id => @user.id, 
                  :security_question => 'Some question',
                  :security_answer => 'Some answer',
                  :format => 'js'
        
        response.status.should == accepted
        
        # try to set it again
        xhr :put, :update_security_question, :user_id => @user.id, 
          :security_question => 'Some question',
          :security_answer => 'Some answer',
          :format => 'js'
        
        response.status.should == unprocessable_entity
        json = JSON.parse(response.body)
        json['error'].should contain('a security question has already been established for this account')
      end
    end
  end
  
  describe "PUT #update_birthday" do
    before do
      @user = FactoryGirl.create(:user)
      test_sign_in(@user)
    end
    describe "for a valid request" do
      before do
        xhr :put, :update_birthday, :user_id => @user.id, 
                  :birthday_month => '1',
                  :birthday_day => '1',
                  :birthday_year => '1990',
                  :format => 'js'
      end
      it "should be successful" do
        response.status.should == accepted
      end
      it "should send the new birthday back as a string via JSON" do
        json = JSON.parse(response.body)
        json['new_birthday'].should == 'January 01, 1990'
      end
    end
  end
  
  describe "PUT #update_notifications" do
    before do
      @user = FactoryGirl.create(:user)
      test_sign_in(@user)
    end
    describe "for a valid request" do
      it "should be successful" do
        xhr :put, :update_notifications, :user_id => @user.id, 
                  :user => { :send_email_for_new_badges => 'true',
                             :send_email_for_new_comments => 'true' },
                  :format => 'js'
        response.status.should == accepted
      end
      it "should update the params correctly" do
        # set them manually to false
        setting = @user.setting
        setting.send_email_for_new_badges = false
        setting.send_email_for_new_comments = false
        setting.save
        
        # make sure they are false
        setting.send_email_for_new_badges.should be_false
        setting.send_email_for_new_comments.should be_false
        
        # update them both to true
        xhr :put, :update_notifications, :user_id => @user.id, 
                  :user => { :send_email_for_new_badges => 'true',
                             :send_email_for_new_comments => 'true' },
                  :format => 'js'
         
        # make sure they are true
        setting.send_email_for_new_badges.should be_true
        setting.send_email_for_new_comments.should be_true
      end
    end
  end
  
  describe "GET #destroy" do
    pending "implementation"
  end
=end

end

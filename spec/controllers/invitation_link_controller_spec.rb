require 'spec_helper'
include DelayedJobSpecHelper 

describe InvitationLinkController do
  
=begin
  describe "authentication" do
    before do 
      @user ||= FactoryGirl.create(:user)
      @userB ||= FactoryGirl.build(:user)
    end
    describe "if not signed in" do
      describe "GET #index" do
        it "should redirect the user to signin page" do
          get :index, :user_id => @user
          response.should redirect_to(:login)
        end
      end
    end
    describe "if signed in" do
      before do
        @userC ||= FactoryGirl.create(:user)
        test_sign_in(@user)
      end
      describe "GET #index" do
        it "should redirect an incorrect user who tries to access another user's invites" do
          get :index, :user_id => @userC
          response.should render_template('errors/error_404')
        end
        it "should show the page if the correct user is viewing it" do
          get :index, :user_id => @user
          response.should render_template('invitations/index')
        end
      end
    end
  end
  
  describe "POST #create" do
    before do
      @user ||= FactoryGirl.create(:user, :name => "The Inviter")
      @userB ||= FactoryGirl.build(:user)
      @userC ||= FactoryGirl.build(:user)
      # clear out old mail
      ActionMailer::Base.deliveries = []
    end
    describe "for a current user" do
      before do
        test_sign_in(@user)
      end
      describe "for a valid request" do
        before do
          # clear out old mail
          ActionMailer::Base.deliveries = []
        end
        it "should email the invitation link" do
          post :create, :recipient_email => @userB.email, :user_id => @user
          
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
        
          last_email_sent = ActionMailer::Base.deliveries.last
          last_email_sent['to'].to_s.should == @userB.email
        end
        it "should email a new invitation for email address using google format" do
          post :create, :recipient_email => "\"Hussain Frosh\" <test1@gmail.com>", :user_id => @user
          
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
        
          last_email_sent = ActionMailer::Base.deliveries.last
          last_email_sent['to'].to_s.should == "test1@gmail.com"
        end
        it "should email a new invitation for email address using google format with comma in name" do
          post :create, :recipient_email => "\"Frosh, Hussain\" <test2@gmail.com>", :user_id => @user
          
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
        
          last_email_sent = ActionMailer::Base.deliveries.last
          last_email_sent['to'].to_s.should == "test2@gmail.com"
        end
        it "should email a new invitation for email addresses using google format with comma" do
          post :create, :recipient_email => "\"Frosh, Hussain\" <test3@gmail.com>, \"Hussain Hussain\" <test4@gmail.com>", :user_id => @user
        
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
        
          first_email_sent = ActionMailer::Base.deliveries.first
          first_email_sent['to'].to_s.should == "test3@gmail.com"
          last_email_sent = ActionMailer::Base.deliveries.last
          last_email_sent['to'].to_s.should == "test4@gmail.com"
        end
        it "should contain the inviting user's name in the subject" do
          post :create, :recipient_email => @userB.email, :user_id => @user
          
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          last_email_sent = ActionMailer::Base.deliveries.last
          last_email_sent['subject'].to_s.should contain("#{@user.name} invited you to join Brevidy!")
        end
        it "should include a personal message with the email if they put one" do
          post :create, :recipient_email => @userB.email, 
                        :personal_message => "Poopie Poopie",
                        :user_id => @user
          
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          last_email_sent = ActionMailer::Base.deliveries.last
          last_email_sent.body.should contain("Poopie Poopie")
        end
        it "should contain the proper invitation link" do
          post :create, :recipient_email => @userB.email, 
                        :personal_message => "Poopie Poopie",
                        :user_id => @user
          
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          last_email_sent = ActionMailer::Base.deliveries.last
          last_email_sent.body.should contain("#{@user.invitation_link.token}")
        end
        it "should NOT include a personal message with the email if they didn't put one" do
          post :create, :recipient_email => @userB.email, 
                        :personal_message => nil,
                        :user_id => @user
          
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          last_email_sent = ActionMailer::Base.deliveries.last
          last_email_sent.body.should_not contain("personal message")
        end
        it "should email multiple invitations when passed multiple emails separated by commas" do
          @userC = FactoryGirl.build(:user)
          recipient_emails = "#{@userB.email}, #{@userC.email}"
          post :create, :recipient_email => recipient_emails, :user_id => @user
          
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          ActionMailer::Base.deliveries.size.should == 2
        end
        it "should redirect and flash a success message" do
          post :create, :recipient_email => @userB.email, :user_id => @user
          response.should redirect_to(user_invitations_path(@user))
          flash[:success].should contain("We have sent an email to each person to ask them to join")
        end
      end
      describe "for an invalid request" do
        it "should return an error if no email address was given" do
          post :create, :recipient_email => nil, :user_id => @user
          response.should redirect_to(user_invitations_path(@user))
          flash[:error].should contain("You have not specified any email addresses to invite")
        end
        it "should return an error if only commas with spaces was found" do
          post :create, :recipient_email => " , ", :user_id => @user
          response.should redirect_to(user_invitations_path(@user))
          flash[:error].should contain("You have not specified any email addresses to invite")
        end
        it "should return an error for invalid email addresses" do
          post :create, :recipient_email => "bad_email@brevidy", :user_id => @user
          response.should redirect_to(user_invitations_path(@user))
          flash[:error].should contain("is an invalid email address")
        end
        it "should return an error if that user is already a member" do
          @userC = FactoryGirl.create(:user)
          post :create, :recipient_email => @userC.email, :user_id => @user
          response.should redirect_to(user_invitations_path(@user))
          flash[:error].should contain("is already a member of Brevidy")
        end
      end
    end
  end
=end
end

require 'spec_helper'
include DelayedJobSpecHelper 
  
describe UserEventsController do
  render_views
  
  before do 
    @video ||= FactoryGirl.create(:video)
    @user ||= test_get_object_owner(@video)
    @userB ||= FactoryGirl.create(:user, :name => "Second User")
    @brevidy ||= FactoryGirl.create(:user, :name => "Brevidy", :email => "marketing@brevidy.com")
  end 
    
=begin
  describe "GET #show" do    
    context "for a valid request" do
      it "should render the correct template" do
        test_sign_in(@user)
        get :show, :user_id => @user
        response.should render_template('user_events/show')
        response.should contain("There is currently no activity to show you")
      end
      context "for event creation and deletion for User A" do
        before do
          # follow event
          @userB.follow!(@user)
          # Add event to activity feed
          UserEvent.delay(:priority => 40).create(:event_type => UserEvent.event_type_value(:relationship), 
                                                  :event_object_id => @userB.relationships.find_by_followed_id(@user).id,
                                                  :user_id => @user.id,
                                                  :event_creator_id => @userB.id)
        
          # badge event
          @icon ||= FactoryGirl.create(:icon)
          @badge ||= FactoryGirl.create(:badge, :video_id => @video.id, :badge_from => @userB.id, :badge_type => @icon.id)
          UserEvent.delay(:priority => 40).create(:event_type => UserEvent.event_type_value(:badge), 
                                                  :event_object_id => @badge.id,
                                                  :user_id => @user.id,
                                                  :event_creator_id => @userB.id)
        
          # comment event
          @comment ||= FactoryGirl.create(:comment, :video_id => @video.id, :user_id => @userB.id)
          UserEvent.delay(:priority => 40).create(:event_type => UserEvent.event_type_value(:comment), 
                                                  :event_object_id => @comment.id,
                                                  :user_id => @user.id,
                                                  :event_creator_id => @userB.id)
        
          # complete all delayed_job tasks such as creating events
          test_complete_all_jobs
        
          test_sign_in(@user)
          # show the page
          get :show, :user_id => @user
        end
        context "when User B starts following User A" do
          it "should add the event to User A's latest activity feed" do
            response.should contain("Second User started following you")
          end
        end
        context "when User B unfollows User A" do
          it "should remove the event from User A's latest activity feed" do
            @userB.unfollow!(@user)
        
            # complete all delayed_job tasks such as creating events
            test_complete_all_jobs
        
            get :show, :user_id => @user
            response.should_not contain("Second User started following you")
          end
        end
        context "when User B badges User A's video" do
          it "should add the event to User A's latest activity feed" do
            response.should contain("Second User gave you a badge for")
          end
        end
        context "when User B unbadges User A's video" do
          it "should remove the event from User A's latest activity feed" do
            @badge.destroy
          
            # complete all delayed_job tasks such as creating events
            test_complete_all_jobs
          
            get :show, :user_id => @user
            response.should_not contain("Second User gave you badge for")
          end
        end
        context "when User B comments on User A's video" do
          it "should add the event to User A's latest activity feed" do
            response.should contain(@comment.content)
          end
        end
        context "when User B deletes their comment on User A's video" do
          it "should remove the event from User A's latest activity feed" do
            @comment.destroy
          
            # complete all delayed_job tasks such as creating events
            test_complete_all_jobs
          
            get :show, :user_id => @user
            response.should_not contain(@comment.content)
          end
        end
      end
      context "when User B comments on User A's video and User A replies to them" do
        it "should add the event to User B's latest activity feed as a comment response" do    
          test_sign_in(@userB)
            
          @reply_comment ||= FactoryGirl.create(:comment, :content => "This is a reply", :video_id => @video.id, :user_id => @user.id)
          UserEvent.delay(:priority => 40).create(:event_type => UserEvent.event_type_value(:comment_response), 
                                                  :event_object_id => @reply_comment.id,
                                                  :user_id => @userB.id,
                                                  :event_creator_id => @user.id)
                             
          # complete all delayed_job tasks such as creating events
          test_complete_all_jobs
          
          get :show, :user_id => @userB.id
          response.should contain("also commented on #{@user.name}'s video")
          response.should contain("This is a reply")
        end
      end
      context "when a bad event object exists (possibly one for which the associated object was deleted)" do
        it "should not throw an error for the user" do
          test_sign_in(@userB)
          
          # create a bad event
          UserEvent.create(:event_type => UserEvent.event_type_value(:badge), 
                           :event_object_id => 999999,
                           :user_id => 999999,
                           :event_creator_id => 999999)
                       
          get :show, :user_id => @userB
          response.should be_success
          response.should render_template('user_events/show')
        end
      end
    end
    
    context "for an invalid request" do
      it "should show an error page if User B tries to access User A's latest activity" do
        test_sign_out
        test_sign_in(@userB)
        
        get :show, :user_id => @user
        response.should render_template('errors/error_404')
      end
    end
  end # end of GET #show
  
=end
end
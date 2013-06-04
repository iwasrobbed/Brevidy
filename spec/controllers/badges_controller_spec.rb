require 'spec_helper'
include DelayedJobSpecHelper

describe BadgesController do
  render_views
  
  before do
    @userB ||= FactoryGirl.create(:user)
    @icon ||= FactoryGirl.create(:icon)
    test_sign_in(@userB)
    # create a temp badge so we can grab a video and user from it
    @video ||= FactoryGirl.create(:video)
    @user ||= test_get_object_owner(@video) 
    @badge ||= FactoryGirl.create(:badge, :video_id => @video.id, :badge_from => @user.id, :badge_type => @icon.id)
    @badge.should be_valid
  end
  
=begin
  describe "GET #badges_dialog" do
    describe "via AJAX" do
      it "should return a list of all badges for a given video" do
        xhr :get, :badges_dialog, :user_id => @user, :video_id => @video, :format => :js
        response.should render_template('badges/badges_dialog')
        response.should contain(@user.name)
        response.should contain('was given by')
        response.should contain('Viewing all badges for this video')
      end
    end
    describe "if showing blocked badges" do
      before do
        @userB.block!(@user)
        
        # give a badge to User C from User A (who we have blocked)
        @videoC ||= FactoryGirl.create(:video)
        @userC ||= test_get_object_owner(@videoC)
        @badgeAtoC ||= FactoryGirl.create(:badge, :video_id => @videoC.id, :badge_from => @user.id, :badge_type => @icon.id)
      
        # make sure the badge exists
        new_badge = Badge.where(:video_id => @videoC.id, :badge_from => @user.id).first
        new_badge.should be_valid
      end
      it "should not show badges from a blocked user on another person's video" do
        # do the same via AJAX
        xhr :get, :badges_dialog, :user_id => @userC, :video_id => @videoC, :format => :js
        response.should render_template('badges/badges_dialog')
        response.should_not contain(@user.name)
        response.should_not contain('was given by')
        response.should contain('Viewing all badges for this video')
      end
    end
  end
  
  describe "GET #index" do
    describe "via the browser" do
      it "should render the badges page showing all badges collected for that user" do
        get :index, :user_id => @user, :video_id => @video
        response.should render_template('badges/index')
        response.should contain('Received 1')
      end
    end
    describe "if the user has blocked someone or been blocked by someone" do
      before do
        @userB.block!(@user)
      end
      it "should say the user can't be found or the user doesn't have permission to view them" do
        get :index, :user_id => @user
        response.should render_template('errors/error_404')
      end
    end
  end
  
  describe "POST #create" do
    describe "for a valid request" do
      before do
        # badge it
        post :create, :video_id => @video.id, 
                      :user_id => @user.id,
                      :badge_type => @icon.id
        # get json response
        @json = JSON.parse(response.body)
      end
      it "should be successful" do
        # created
        response.status.should == created
      end
      it "should render the new badge to JSON as :html" do
        @json['html'].should_not be_nil
        @json['html'].should have_selector('i.' + @icon.css_class + '_Medium')
      end
      it "should contain the right badge count in the new badge" do
        @json['html'].should have_selector('span', :content => "#{@video.badges_count_for_type_and_current_user(@icon.id, @userB)}")
      end
      it "should render the unbadge link to JSON as :unbadge" do
        @json['unbadge'].should_not be_nil
        @json['unbadge'].should have_selector('a.unBadge')
      end
      it "should render the view all badges link to JSON as :view_all_badges_link" do
        @json['view_all_badges_link'].should_not be_nil
        @json['view_all_badges_link'].should contain('view all')
      end
      it "should have the total badges given to this video" do
        @json['total_video_badges'].should_not be_nil
        @json['total_video_badges'].should == @video.badges_count_viewable_by(@userB)
      end
      it "should have the total badges given to the user for all videos" do
        @json['total_user_badges'].should_not be_nil
        @json['total_user_badges'].should == @user.badges_count_viewable_by(@userB)
      end
      it "should contain the video owner ID" do
        @json['video_owner_id'].should_not be_nil
        @json['video_owner_id'].should == @user.id
      end
      it "should contain the video ID" do
        @json['video_id'].should_not be_nil
        @json['video_id'].should == @video.id
      end
    end
    describe "for event creation" do
      it "should create a new event object for User A if User B gave User A a badge" do
        # post a new badge
        post :create, :video_id => @video.id, 
                      :user_id => @user.id,
                      :badge_type => @icon.id
        badge = Badge.last

        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs
       
        UserEvent.where(:event_type => UserEvent.event_type_value(:badge), 
                        :event_object_id => badge.id,
                        :user_id => @user.id,
                        :event_creator_id => @userB.id).should exist
      end
      it "should not create a new event object for User B if User B gave themselves a badge" do
        @videoB ||= FactoryGirl.create(:video, :user_id => @userB.id)
        
        # post a new badge
        post :create, :video_id => @videoB.id, 
                      :user_id => @userB.id,
                      :badge_type => @icon.id
        badge = Badge.last

        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs
       
        UserEvent.where(:event_type => UserEvent.event_type_value(:badge), 
                        :event_object_id => badge.id,
                        :user_id => @userB.id,
                        :event_creator_id => @userB.id).should_not exist
      end
    end
    describe "for email notifications" do
      it "should only send an e-mail to the video owner if they have that notification setting enabled and if they didn't create the badge" do
        # clear out old mail
        ActionMailer::Base.deliveries = []
        
        # enable email notification
        setting = @user.setting
        setting.send_email_for_new_badges = true
        setting.save
        
        # post a new badge
        post :create, :video_id => @video.id, 
                      :user_id => @user.id,
                      :badge_type => @icon.id
                      
        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs
        
        # confirm an email was sent
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent['to'].to_s.should == @user.email
        last_email_sent['subject'].to_s.should contain("New badge on your video")
        
        # clear out old mail
        ActionMailer::Base.deliveries = []
        
        # disable email notification
        setting.send_email_for_new_badges = false
        setting.save
        
        # post a new badge
        post :create, :video_id => @video.id, 
                      :user_id => @user.id,
                      :badge_type => @icon.id
                      
        # confirm an email was NOT sent
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent.should be_nil
      end
    end
    describe "for an invalid request" do
      it "should not let someone badge a video that is processing" do
        @video.status = VideoGraph.get_status_number(:transcoding)
        @video.save
        
        post :create, :video_id => @video.id, 
              :user_id => @user.id,
              :badge_type => @icon.id
        # get json response
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain("that video is still processing")
        # unauthorized
        response.status.should == unauthorized
      end
      it "should return a 404 if an associated video is not found" do
        # give it a bad video id
        post :create, :video_id => "999999", 
                      :user_id => @user.id,
                      :badge_type => @icon.id
        # get json response
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain("That video could not be found or a badge type was not passed in")
        # not found
        response.status.should == not_found
      end
      it "should return a 404 if a badge type was not passed in" do
        # give it a nil badge type
        post :create, :video_id => @video.id, 
                      :user_id => @user.id,
                      :badge_type => nil
        # get json response
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain("That video could not be found or a badge type was not passed in")
        # not found
        response.status.should == not_found
      end
      it "should not let a user badge a video more than once using the same badge type" do
        # badge it once
        post :create, :video_id => @video.id, 
                      :user_id => @user.id,
                      :badge_type => @icon.id
        # created
        response.status.should == created
        # now try to badge it again using the same badge
        post :create, :video_id => @video.id, 
                      :user_id => @user.id,
                      :badge_type => @icon.id
        # get json response
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain("You have already badged this video using that badge")          
        # unprocessable entity
        response.status.should == unprocessable_entity
      end
      it "should not let a user badge a video if they were blocked by that video owner" do
        # have the video owner block user B
        @user.block!(@userB)
        
        # try to badge user's video as userB
        post :create, :video_id => @video.id, 
                      :user_id => @user.id,
                      :badge_type => @icon.id
                      
        response.should render_template('errors/error_404')
      end
    end
  end
  
  describe "DELETE #destroy" do
    describe "for a valid request" do
      before do      
        # login the user that created the original badge
        test_sign_in(@user)                   
        # destroy it
        post :destroy, :id => @badge.id,
                       :video_id => @video.id, 
                       :user_id => @user.id
        # get json response
        @json = JSON.parse(response.body)
      end
      it "should destroy the badge" do
        response.status.should == ok
      end
      it "should have the total badges given to this video" do
        @json['total_video_badges'].should_not be_nil
        @json['total_video_badges'].should == @video.badges_count_viewable_by(@user)
      end
      it "should have the total badges given to the user for all videos" do
        @json['total_user_badges'].should_not be_nil
        @json['total_user_badges'].should == @user.badges_count_viewable_by(@user)
      end
      it "should contain the video owner ID" do
        @json['video_owner_id'].should_not be_nil
        @json['video_owner_id'].should == @user.id
      end
      it "should contain the video ID" do
        @json['video_id'].should_not be_nil
        @json['video_id'].should == @video.id
      end
      it "should contain the path to the user's badges" do
        @json['badges_path'].should_not be_nil
        @json['badges_path'].should contain("#{user_video_badges_dialog_path(@user, @video)}")
      end
      it "should contain the number of times this badge type has been used on the video" do
        @json['this_badge_count'].should_not be_nil
        @json['this_badge_count'].should contain("#{@video.badges_count_for_type_and_current_user(@badge.badge_type, @user)}")
      end
      it "should contain the badge's name to display" do
        @json['badge_name'].should_not be_nil
        @json['badge_name'].should contain("#{@icon.name}")
      end
    end
    describe "for event deletion" do
      it "should delete the event object for User A if User B unbadged User A's video" do
        # badge it
        post :create, :video_id => @video.id, 
                      :user_id => @user.id,
                      :badge_type => @icon.id
        badge_to_delete = Badge.last 
        
        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs             
        
        user_event = UserEvent.where(:event_type => UserEvent.event_type_value(:badge), 
                                     :event_object_id => badge_to_delete.id,
                                     :user_id => @user.id,
                                     :event_creator_id => @userB.id)
        user_event.first.should be_valid
        
        post :destroy, :id => badge_to_delete.id,
                       :video_id => @video.id, 
                       :user_id => @user.id
                       
        # complete all delayed_job tasks such as sending mail
        test_complete_all_jobs
       
        user_event.should_not exist
      end
    end
    describe "for an invalid request" do
      it "should not let User B destroy a badge that User A created" do
        # login the user that didn't create the badge
        test_sign_in(@userB)                   
        # destroy it
        post :destroy, :id => @badge.id,
                       :video_id => @video.id, 
                       :user_id => @user.id
        # get json response
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain("You do not own that badge")
        # unauthorized
        response.status.should == unauthorized
      end
      it "should return a 404 if an associated video is not found" do
        # pass in a badge video id
        post :destroy, :id => @badge.id,
                       :video_id => "999999", 
                       :user_id => @user.id
        response.status.should == not_found
      end 
      it "should return a 404 if an associated badge is not found on that video" do
        # pass in a bad badge ID
        post :destroy, :id => "999999",
                       :video_id => @video.id, 
                       :user_id => @user.id
        response.status.should == not_found
      end
    end
  end
=end
end
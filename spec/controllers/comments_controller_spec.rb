require 'spec_helper'
include ActionView::Helpers::TextHelper
include ActionView::Helpers::UrlHelper
include DelayedJobSpecHelper

describe CommentsController do
  render_views
  
=begin  
  describe "POST #create" do
    before do
      @video ||= FactoryGirl.create(:video)
      @user ||= test_get_object_owner(@video)
      test_sign_in(@user)
      @userB ||= FactoryGirl.create(:user)
      @userC ||= FactoryGirl.create(:user)
    end
    describe "for blocked users" do
      it "should not let a blocked user comment on the other person's video" do
        @userB.block!(@user)
        
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @userB.id, 
                      :format => 'js'
      
        response.should render_template('errors/error_404')
      end
    end
    describe "for an invalid request" do
      it "should not let someone comment on a video that is processing" do
        @video.status = VideoGraph.get_status_number(:transcoding)
        @video.save
        
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @user.id, 
                      :format => 'js'
                      
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
                      :content => "weeee", 
                      :user_id => @user.id, 
                      :format => 'js'
        # not found
        response.status.should == not_found
      end
      it "should render validation/save errors via json" do
        # give it too long of a comment length
        comment_content = "a" * 2501
        post :create, :video_id => @video.id, 
                      :content => comment_content, 
                      :user_id => @user.id, 
                      :format => 'js'
        # get json response
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain("Your comment must be less than")
        # unprocessable entity
        response.status.should == unprocessable_entity
      end
    end
    describe "for a valid request" do
      it "should save the comment" do
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @user.id, 
                      :format => 'js'
        # created
        response.status.should == created
      end
      it "should render the comment as HTML via json" do
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @user.id, 
                      :format => 'js'
        # get json response
        json = JSON.parse(response.body)
        json['html'].should_not be_nil
        json['html'].should contain("weeee")
      end
      it "should automatically generate links" do
        post :create, :video_id => @video.id, 
                      :content => "http://www.brevidy.com", 
                      :user_id => @user.id, 
                      :format => 'js'
        # get json response
        json = JSON.parse(response.body)
        json['html'].should_not be_nil
        json['html'].should have_selector("a.inlinelink")
        # webrat's "contain" removes all html, so just check for proper link
        json['html'].should contain("http://www.brevidy.com")
      end
      it "should return the new comments count for the video via json" do
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @user.id, 
                      :format => 'js'
        # get json response
        json = JSON.parse(response.body)
        json['comments_count'].should_not be_nil
        json['comments_count'].should contain("#{@video.comments.count}")
      end
      it "should return the video ID via json" do
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @user.id, 
                      :format => 'js'
        # get json response
        json = JSON.parse(response.body)
        json['video_id'].should_not be_nil
        json['video_id'].should contain("#{@video.id}")
      end
      describe "for event creation" do
        it "should create a new event object for User A if User B commented on User A's video" do
          test_sign_out
          test_sign_in(@userB)
          
          # create a comment as User B on User A's video
          post :create, :video_id => @video.id, 
                        :content => "rhinos are awesome", 
                        :user_id => @userB.id, 
                        :format => 'js'
          # created
          response.status.should == created
          
          comment = Comment.last

          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          # we have to do this twice since the first time just creates a delayed_job
          test_complete_all_jobs
          
          UserEvent.where(:event_type => UserEvent.event_type_value(:comment), 
                          :event_object_id => comment.id,
                          :user_id => @user.id,
                          :event_creator_id => @userB.id).should exist
        end
        it "should not create a new event object for User A if User A commented on their own video" do
          # create a comment as User A on User A's video
          post :create, :video_id => @video.id, 
                        :content => "weeee", 
                        :user_id => @user.id, 
                        :format => 'js'
          # created
          response.status.should == created
        
          comment = Comment.last

          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          # we have to do this twice since the first time just creates a delayed_job
          test_complete_all_jobs
       
          UserEvent.where(:event_type => UserEvent.event_type_value(:comment), 
                          :event_object_id => comment.id,
                          :user_id => @user.id,
                          :event_creator_id => @user.id).should_not exist
        end
        it "should create a new event object for other users in the conversation when someone replies" do
          test_sign_out
          test_sign_in(@userB)
          
          # create a comment as User B on User A's video
          post :create, :video_id => @video.id, 
                        :content => "weeee", 
                        :user_id => @userB.id, 
                        :format => 'js'
          # created
          response.status.should == created
        
          comment = Comment.last

          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          # we have to do this twice since the first time just creates a delayed_job
          test_complete_all_jobs
       
          UserEvent.where(:event_type => UserEvent.event_type_value(:comment), 
                          :event_object_id => comment.id,
                          :user_id => @user.id,
                          :event_creator_id => @userB.id).should exist
                          
          # now create a comment as User C and see if User B gets notified about it
          test_sign_out
          test_sign_in(@userC)
          
          # create a comment as User C on User A's video
          post :create, :video_id => @video.id, 
                        :content => "weeee", 
                        :user_id => @userC.id, 
                        :format => 'js'
          # created
          response.status.should == created
          
          comment = Comment.last

          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          # we have to do this twice since the first time just creates a delayed_job
          test_complete_all_jobs
       
          UserEvent.where(:event_type => UserEvent.event_type_value(:comment_response), 
                          :event_object_id => comment.id,
                          :user_id => @userB.id,
                          :event_creator_id => @userC.id).should exist
        end
      end
      it "should only send an e-mail to the video owner if they have that notification setting enabled" do
        # clear out old mail
        ActionMailer::Base.deliveries = []
        
        # enable email notification
        setting = @user.setting
        setting.send_email_for_new_comments = true
        setting.save
        
        # sign out as User A and sign in as User B
        test_sign_out
        test_sign_in(@userB)
        
        # post a new comment as User B (on User A's video)
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @userB.id, 
                      :format => 'js'            
        
        # process notify_all_users_in_conversation job
        test_complete_all_jobs
        # send emails out
        test_complete_all_jobs
        
        # confirm an email was sent
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent.should_not be_blank
        last_email_sent['to'].to_s.should == @user.email
        last_email_sent['subject'].to_s.should contain("#{@user.name} just commented on your video")
        
        # clear out old mail
        ActionMailer::Base.deliveries = []
        
        # disable email notification
        setting = @user.setting
        setting.send_email_for_new_comments = false
        setting.save
        
        # try to post another comment as User B and see
        # if User A is notified this time (they shouldn't be)
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @userB.id, 
                      :format => 'js'
              
        # process notify_all_users_in_conversation job
        test_complete_all_jobs
        # send emails out
        test_complete_all_jobs      
                      
        # confirm an email was NOT sent
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent.should be_nil
      end
      it "should not send an e-mail to the video owner if they commented on their own video" do
        # clear out old mail
        ActionMailer::Base.deliveries = []
        
        # disable email notification
        setting = @user.setting
        setting.send_email_for_new_comments = true
        setting.save
        
        # try to post a comment as User A and see
        # if User A is notified of their own comment (they shouldn't be)
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @user.id, 
                      :format => 'js'
              
        # process notify_all_users_in_conversation job
        test_complete_all_jobs
        # send emails out
        test_complete_all_jobs      
                      
        # confirm an email was NOT sent
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent.should be_nil
      end
      it "should send an e-mail to others in the conversation if they have that notification setting enabled" do
        # clear out old mail
        ActionMailer::Base.deliveries = []
        
        # enable email notification
        setting = @userB.setting
        setting.send_email_for_replies_to_a_prior_comment = true
        setting.save
        
        # sign out as User A and sign in as User B
        test_sign_out
        test_sign_in(@userB)
        
        # post a new comment as User B (on User A's video)
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @userB.id, 
                      :format => 'js'            
        
        # process notify_all_users_in_conversation job
        test_complete_all_jobs
        # send emails out
        test_complete_all_jobs
        
        # confirm an email was sent
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent.should_not be_blank
        last_email_sent['to'].to_s.should == @user.email
        last_email_sent['subject'].to_s.should contain("#{@userB.name} just commented on your video")
        
        # clear out old mail
        ActionMailer::Base.deliveries = []
        
        # sign out as User B and sign in as User A
        test_sign_out
        test_sign_in(@user)
        
        # post a new comment as User A (on their own video)
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @user.id, 
                      :format => 'js'
         
        # process notify_all_users_in_conversation job
        test_complete_all_jobs
        # send emails out
        test_complete_all_jobs 
                      
        # confirm an email was sent to others in the conversation
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent.should_not be_blank
        last_email_sent['to'].to_s.should == @userB.email
        last_email_sent['subject'].to_s.should contain("#{@user.name} also commented on #{@user.name}'s video")
        
        # check that there was only one e-mail sent since we don't
        # send an email to the person who commented or that owns the video
        all_sent_emails = ActionMailer::Base.deliveries
        all_sent_emails.each do |e|
          e['to'].to_s.should_not == @user.email
          e['subject'].to_s.should_not contain("#{@user.name} just commented on your video")
        end
        
        # clear out old mail
        ActionMailer::Base.deliveries = []
        
        # change the settings and make sure it doesn't send the email
        setting = @userB.setting
        setting.send_email_for_replies_to_a_prior_comment = false
        setting.save
        
        # post a new comment as User A (on their own video)
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @user.id, 
                      :format => 'js'
         
        # process notify_all_users_in_conversation job
        test_complete_all_jobs
        # send emails out
        test_complete_all_jobs 
                      
        # confirm an email was NOT sent to User B this time
        last_email_sent = ActionMailer::Base.deliveries.last
        last_email_sent.should be_nil
      end
      it "should not send an email to the person who commented, only to others in the conversation if they have that notification setting enabled" do
        # clear out old mail
        ActionMailer::Base.deliveries = []
        
        # enable email notifications for all people in conversation
        settingA = @user.setting
        settingA.send_email_for_new_comments = true
        settingA.save
        settingB = @userB.setting
        settingB.send_email_for_replies_to_a_prior_comment = true
        settingB.save
        
        # post a new comment as User A (on User A's video)
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @user.id, 
                      :format => 'js'    
        
        # sign out as User A and sign in as User B
        test_sign_out
        test_sign_in(@userB)
        
        # post a new comment as User B (on User A's video)
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @userB.id, 
                      :format => 'js'    
           
        # sign out as User A and sign in as User B
        test_sign_out
        test_sign_in(@userC)   
                      
        # post a new comment as User C (on User A's video)
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @userC.id, 
                      :format => 'js'            
        
        # process notify_all_users_in_conversation job
        test_complete_all_jobs
        # send emails out
        test_complete_all_jobs
        
        # clear out old mail
        ActionMailer::Base.deliveries = []
        
        # now that everyone has commented on the video, let's post
        # another comment as User C and see if User C is notified 
        # of the new comment
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @userC.id, 
                      :format => 'js' 
        
        # process notify_all_users_in_conversation job
        test_complete_all_jobs
        # send emails out
        test_complete_all_jobs
        
        # check that there was only one e-mail sent since we don't
        # send an email to the person who commented or that owns the video
        all_sent_emails = ActionMailer::Base.deliveries
        all_sent_emails.should_not be_blank
        all_sent_emails.each do |e|
          e['to'].to_s.should_not == @userC.email
        end
        
        # disable email notifications for all people in conversation
        settingA = @user.setting
        settingA.send_email_for_new_comments = false
        settingA.save
        settingB = @userB.setting
        settingB.send_email_for_replies_to_a_prior_comment = false
        settingB.save
        
        # clear out old mail
        ActionMailer::Base.deliveries = []
        
        # now that everyone has disabled their email notifications,
        # let's make sure no emails are sent to either of the other
        # commenters 
        post :create, :video_id => @video.id, 
                      :content => "weeee", 
                      :user_id => @userC.id, 
                      :format => 'js' 
        
        # process notify_all_users_in_conversation job
        test_complete_all_jobs
        # send emails out
        test_complete_all_jobs
        
        # this also tests that it only sends one e-mail to the video_owner even if the video_owner is in the conversation
        #
        # check that there was only one e-mail sent since we don't
        # send an email to the person who commented or that owns the video
        all_sent_emails = ActionMailer::Base.deliveries
        all_sent_emails.should be_blank
      end
    end
  end
  
  describe "DELETE #destroy" do
    before do
      @video = FactoryGirl.create(:video)
      @user = test_get_object_owner(@video)
      # create a comment associated with a video & user
      @comment ||= FactoryGirl.create(:comment, :user_id => @user.id, :video_id => @video.id)
      test_sign_in(@user)
      @userB ||= FactoryGirl.create(:user)
      @userC ||= FactoryGirl.create(:user)
    end
    describe "for an invalid request" do
      it "should return a 404 if an associated video is not found" do
        # give it a bad video id
        post :destroy, :id => @comment.id, 
                       :video_id => "999999", 
                       :user_id => @user.id, 
                       :format => 'js'
        # not found
        response.status.should == not_found
      end
      it "should return a 404 if the comment is not found" do
        # give it a bad comment id
        post :destroy, :id => "999999", 
                       :video_id => @video.id,  
                       :user_id => @user.id, 
                       :format => 'js'
        # not found
        response.status.should == not_found
      end
      it "should NOT let User B delete User A's comment if User A also owns the video" do
        # set the current user to user B who owns neither the comment nor the video
        test_sign_out
        test_sign_in(@userB)
        
        # try to destroy it logged in as user B
        post :destroy, :id => @comment.id, 
                       :video_id => @video.id, 
                       :user_id => @user.id, 
                       :format => 'js'
        # get json response
        json = JSON.parse(response.body)
        json['error'].should_not be_nil
        json['error'].should contain("You do not own that comment")
        # unauthorized
        response.status.should == unauthorized
      end
    end
    
    describe "for a valid request" do
      it "should let a user delete their own comment" do
        post :destroy, :id => @comment.id, 
                       :video_id => @video.id, 
                       :user_id => @user.id, 
                       :format => 'js'
        # ok
        response.status.should == ok
      end
      it "should let User A delete User B's comment if User A owns the video" do
        # set the comment owner to user B
        @comment.user_id = @userB.id
        @comment.save!
        # some quick checks to make sure ownerships are set up correctly
        #puts "Comment owner should be #{@userB.id} and is #{@comment.user_id}"
        #puts "Current user should be #{@user.id} and is #{controller.current_user.id}"
        #puts "Video owner should be #{@user.id} and is #{test_get_object_owner(@video).id}"
        # destroy it logged in as user A
        post :destroy, :id => @comment.id, 
                       :video_id => @video.id, 
                       :user_id => @user.id, 
                       :format => 'js'
        # ok
        response.status.should == ok
      end
      it "should return the comments count via json" do
        post :destroy, :id => @comment.id, 
                       :video_id => @video.id, 
                       :user_id => @user.id, 
                       :format => 'js'        
       # get json response
       json = JSON.parse(response.body)
       json['comments_count'].should_not be_nil
       json['comments_count'].should contain("#{@video.comments.count}")
      end
      describe "for event deletion" do
        it "should remove the associated event object for User A if User B deleted their comment on User A's video" do
          test_sign_out
          test_sign_in(@userB)
          
          # create a comment as User B on User A's video
          post :create, :video_id => @video.id, 
                        :content => "rhinos are awesome", 
                        :user_id => @userB.id, 
                        :format => 'js'
          # created
          response.status.should == created
          
          comment = Comment.last

          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          # we have to do this twice since the first time just creates a delayed_job
          test_complete_all_jobs
          
          user_event = UserEvent.where(:event_type => UserEvent.event_type_value(:comment), 
                                       :event_object_id => comment.id,
                                       :user_id => @user.id,
                                       :event_creator_id => @userB.id)
          user_event.should exist
          
          post :destroy, :id => comment.id, 
                         :video_id => @video.id, 
                         :user_id => @userB.id, 
                         :format => 'js'  
          
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
        
          user_event.should_not exist
        end
        it "should remove the associated event object for other users in the conversation when someone deletes their comment on User A's video" do
          test_sign_out
          test_sign_in(@userB)
          
          # create a comment as User B on User A's video
          post :create, :video_id => @video.id, 
                        :content => "weeee", 
                        :user_id => @userB.id, 
                        :format => 'js'
          # created
          response.status.should == created
        
          comment = Comment.last

          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          # we have to do this twice since the first time just creates a delayed_job
          test_complete_all_jobs
       
          UserEvent.where(:event_type => UserEvent.event_type_value(:comment), 
                          :event_object_id => comment.id,
                          :user_id => @user.id,
                          :event_creator_id => @userB.id).should exist
                          
          # now create a comment as User C and see if User B gets notified about it
          test_sign_out
          test_sign_in(@userC)
          
          # create a comment as User C on User A's video
          post :create, :video_id => @video.id, 
                        :content => "weeee", 
                        :user_id => @userC.id, 
                        :format => 'js'
          # created
          response.status.should == created
          
          comment = Comment.last

          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
          
          # we have to do this twice since the first time just creates a delayed_job
          test_complete_all_jobs
       
          user_event = UserEvent.where(:event_type => UserEvent.event_type_value(:comment_response), 
                                       :event_object_id => comment.id,
                                       :user_id => @userB.id,
                                       :event_creator_id => @userC.id)
          user_event.should exist
          
          # Now destroy that comment
          post :destroy, :id => comment.id, 
                         :video_id => @video.id, 
                         :user_id => @userC.id, 
                         :format => 'js'  
          
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs
        
          user_event.should_not exist
        end
      end
    end
  end
=end
end
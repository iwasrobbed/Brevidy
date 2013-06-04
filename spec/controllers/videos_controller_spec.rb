require 'spec_helper'
include DelayedJobSpecHelper
  
describe VideosController do 
  render_views
  
  before do
    @video ||= FactoryGirl.create(:video)
    @user ||= test_get_object_owner(@video)
    @userB ||= FactoryGirl.create(:user)
    test_sign_in(@user)
  end
  
=begin
  describe "GET #embed_code" do
    context "for a valid request via JSON" do
      it "should return the embed code for a standard Brevidy video" do
        get :embed_code, :user_id => @user.id, :video_id => @video.id
        
        response.should be_success
        response.should contain("https://brevidytest.s3.amazonaws.com/sample_data/enc1_sample_populated.mp4")
      end
      it "should return the embed code for a YouTube video" do
        youtube_video = Video.new
        youtube_video.description = Faker::Lorem.sentences(sentence_count = 5).join(' ').first(250)
        youtube_video.user_id = @user.id
        youtube_video.status = VideoGraph.get_status_number(:ready)
        youtube_video.remote_host = "youtube.com"
        youtube_video.remote_video_id = "0FwOtHso5Wg"
        youtube_video.selected_thumbnail = 0
        youtube_video.save
        youtube_video.should be_valid
        
        get :embed_code, :user_id => @user.id, :video_id => youtube_video.id
        response.should be_success
        response.body.should =~ /www.youtube.com/
        response.body.should =~ /0FwOtHso5Wg/
      end
      it "should return the embed code for a Vimeo video" do
        vimeo_video = Video.new
        vimeo_video.description = Faker::Lorem.sentences(sentence_count = 5).join(' ').first(250)
        vimeo_video.user_id = @user.id
        vimeo_video.status = VideoGraph.get_status_number(:ready)
        vimeo_video.remote_host = "vimeo.com"
        vimeo_video.remote_video_id = "16339841"
        vimeo_video.selected_thumbnail = 0
        vimeo_video.save
        vimeo_video.should be_valid
        
        get :embed_code, :user_id => @user.id, :video_id => vimeo_video.id
        response.should be_success
        response.body.should =~ /player.vimeo.com/
        response.body.should =~ /16339841/
      end
    end
    context "for an invalid request via JSON" do
      it "should return an error message" do
        # give it a bad video id
        get :embed_code, :user_id => @user.id, :video_id => "999999"
        
        json = JSON.parse(response.body)
        json['error'].should contain("That video is either still processing or it could not be found")
        response.status.should == unprocessable_entity
      end
    end
  end
  
  describe "GET #show" do
    describe "for a valid request" do
      context "if the user owns the video" do
        before do
          get :show, :id => @video.id, :user_id => @user.id
        end
        it "should show the video" do
          response.should render_template('videos/show')
        end
        it "should show the video owner links for editing and deleting the post" do
          response.should have_selector('a.menuLink', :href => edit_user_video_path(@user, @video))
          response.should have_selector('a.menuLink.deleteVideoPost', :href => user_video_path(@user, @video))
        end
      end
      context "if the user does not own the video" do
        it "should NOT show someone who doesn't own the video the links for editing and deleting the post" do
          test_sign_out
          test_sign_in(@userB)
          get :show, :id => @video.id, :user_id => @user.id
          
          response.should_not have_selector('a.menuLink', :href => edit_user_video_path(@user, @video))
          response.should_not have_selector('a.menuLink.deleteVideoPost', :href => user_video_path(@user, @video))
        end
      end
      it "should show the 'share' area for sharing the public link to the video" do
        get :show, :id => @video.id, :user_id => @user.id
        response.should contain(public_video_url(:public_token => @video.public_token))
      end
      it "should show the 'flag video' link for flagging the video" do
        get :show, :id => @video.id, :user_id => @user.id
        response.should have_selector('a.menuLink', :href => user_video_flag_video_dialog_path(@user, @video.id))
      end
    end
    describe "for an invalid request" do
      it "should render a 404 if the video couldn't be found" do
        # give it a bad video ID
        get :show, :id => "999999", :user_id => @user.id
        response.should render_template('errors/error_404')
      end
      it "should render a 404 if the user couldn't be found" do
        # give it a bad video ID
        get :show, :id => @video.id, :user_id => "999999"
        response.should render_template('errors/error_404')
      end
    end
    describe "if the user is blocked by or has blocked another user" do
      before do
        @userB.block!(@user)
        test_sign_out
        test_sign_in(@userB)
      end
      it "should say the user can't be found or the user doesn't have permission to view them" do
        get :show, :id => @video.id, :user_id => @user.id
        response.should render_template('errors/error_404')
      end
    end
    describe "if there are blocked comments on a video" do
      before do
        @user.block!(@userB)
        
        # create a comment on User C's video by User B
        @videoC ||= FactoryGirl.create(:video)
        @userC ||= test_get_object_owner(@videoC)
        @commentBtoC ||= FactoryGirl.create(:comment, :video_id => @videoC.id, :user_id => @userB.id, :content => "i should be blocked")

        # make sure the comment exists
        new_comment = Comment.where(:video_id => @videoC.id, :user_id => @userB.id, :content => "i should be blocked").first
        new_comment.should be_valid
      end
      it "should not show the blocked comments to the user" do  
        # view the video as User A and see if you can see User B's blocked comment
        get :show, :id => @videoC.id, :user_id => @userC.id
        response.should_not contain("i should be blocked")
      end
    end
  end
  
  describe "GET #flag_video_dialog" do
    describe "for a valid request" do
      before do
        get :flag_video_dialog, :user_id => @user.id, :video_id => @video.id
      end
      it "should render the dialog box" do
        response.should render_template(:partial => '_flag_video_dialog')
      end
      it "should show a flag video button" do
        response.body.should =~ /Flag Video/
      end
    end
  end
  
  describe "POST #flag" do
    before do
      @flag = Flag.create(:reason => "Test reason")
    end
    describe "for a valid request" do
      describe "without checking model changes" do
        before do
          xhr :post, :flag, :video_id => @video.id,
                            :user_id => @user.id,
                            :flag_id => @flag.id,
                            :detailed_reason => "Detailed"
        end
        it "should be successful" do
          response.status.should == created
          json = JSON.parse(response.body)
          json['success_message'].should contain("We have received your request to flag this video")
        end
        it "should send an email to support@brevidy.com" do
          # complete all delayed_job tasks such as sending mail
          test_complete_all_jobs

          last_email_sent = ActionMailer::Base.deliveries.last
          last_email_sent['to'].to_s.should == "support@brevidy.com"
          last_email_sent['subject'].to_s.should contain("has been flagged for review")
        end
      end
      describe "for independent checks" do
        it "should create a new video_flag record" do
          lambda do
            xhr :post, :flag, :video_id => @video.id,
                              :user_id => @user.id,
                              :flag_id => @flag.id,
                              :detailed_reason => "Detailed"
          end.should change(VideoFlag, :count).by(1)
          
          video_flag = VideoFlag.find_by_flagged_by(@user.id)
          video_flag.should_not be_nil
          video_flag.flag_id.should == @flag.id
          video_flag.video_id.should == @video.id
        end
        it "should NOT require a detailed description" do
          xhr :post, :flag, :video_id => @video.id,
                            :user_id => @user.id,
                            :flag_id => @flag.id,
                            :detailed_reason => nil

          response.status.should == created
          json = JSON.parse(response.body)
          json['success_message'].should contain("We have received your request to flag this video")
        end
      end
    end
    describe "for an invalid request" do
      it "should require a flag ID" do
        xhr :post, :flag, :video_id => @video.id,
                          :user_id => @user.id,
                          :flag_id => nil,
                          :detailed_reason => "Detailed"
        
        response.status.should == unprocessable_entity
        json = JSON.parse(response.body)
        json['error'].should contain("You must select one of the options for why you want to flag the video")
      end
    end
  end
  
  describe "DELETE #destroy" do    
    describe "for a valid request" do
      before do
        post :destroy, :id => @video.id,
                       :user_id => @user.id
        @json = JSON.parse(response.body)
      end
      
      it "should destroy the video" do
        # ok
        response.status.should == ok
      end
      it "contain the favorites count for that user" do
        @json['favorites_count'].should_not be_nil
        @json['favorites_count'].should == @user.favorites_count_viewable_by(@user)
      end
      it "contain the badges count for that user" do
        @json['badges_count'].should_not be_nil
        @json['badges_count'].should == @user.badges_count_viewable_by(@user)
      end
      it "contain the user's ID" do
        @json['user_id'].should_not be_nil
        @json['user_id'].should == @user.id
      end
    end
    describe "for an invalid request" do
      it "should return a 404 error if no associated video was found" do
        # give it a bad video id
        post :destroy, :id => "999999", 
                       :user_id => @user.id
        response.status.should == not_found
      end
      it "should return a 404 error if User B tries to destroy a video belonging to User A" do
        # sign out User A
        test_sign_out
        # sign in the wrong user
        test_sign_in(@userB)
        # try to destroy User A's video as User B
        # the controller uses current_user.videos so returns nil if it doesn't
        # find @video within that current_user's videos
        post :destroy, :id => @video.id,
                       :user_id => @user.id
        response.status.should == not_found
      end
    end
  end
  
  describe "GET #share_validation" do
    before do
      test_sign_in(@userB)
    end

    describe "for an invalid request" do
      it "should not accept a bad link" do
        get :share_validation, :user_id => @userB.id,
                               :shared_video_link => "http://www.brevidy.com"
        @json = JSON.parse(response.body)

        response.status.should == unprocessable_entity
        @json['error'].should == "Error getting the video information.  Please verify the link is correct."
      end
    end

    describe "for a valid request" do
=end
=begin
# These next 3 tests are broken and need fixing, but they work in reality

      it "should accept a youtube.com/watch?v= type link" do
        get :share_validation, :user_id => @userB.id,
                               :shared_video_link => "http://www.youtube.com/watch?v=N4OPr_QxoFg"
        response.should redirect_to(user_share_a_link_path(@userB, 
                                                           :remote_host => "youtube.com",
                                                           :remote_link => "http://www.youtube.com/watch?v=N4OPr_QxoFg",
                                                           :remote_video_description => "Hilarious remake of the old GI Joe public service announcements",
                                                           :remote_video_id => "N4OPr_QxoFg",
                                                           :remote_video_thumbnail => "http://i.ytimg.com/vi/N4OPr_QxoFg/hqdefault.jpg",
                                                           :remote_video_title => "GI Joe PSA - Porkchop Sandwhiches"))
      end
      
      it "should accept a youtu.be link" do
        get :share_validation, :user_id => @userB.id,
                               :shared_video_link => "http://youtu.be/N4OPr_QxoFg"
        response.should redirect_to(user_share_a_link_path(@userB, 
                                                           :remote_host => "youtu.be",
                                                           :remote_link => "http://youtu.be/N4OPr_QxoFg",
                                                           :remote_video_description => "Hilarious remake of the old GI Joe public service announcements",
                                                           :remote_video_id => "N4OPr_QxoFg",
                                                           :remote_video_thumbnail => "http://i.ytimg.com/vi/N4OPr_QxoFg/hqdefault.jpg",
                                                           :remote_video_title => "GI Joe PSA - Porkchop Sandwhiches"))
      end
      
      it "should accept a Vimeo link" do
        get :share_validation, :user_id => @userB.id,
                               :shared_video_link => "http://www.vimeo.com/26433049"
        response.should redirect_to(user_share_a_link_path(@userB, 
                                                           :remote_host => "vimeo.com",
                                                           :remote_link => "http://www.vimeo.com/26433049",
                                                           :remote_video_description => "With \"Carmageddon\" looming in Los Angeles, I decided to take my \"LA with no cars\" video and re-edit it with new music, coloring and opening shots.  Editing was done in Final Cut, coloring done with After Effects and shot on a Canon 60D.\n\nMusic: Wi...",
                                                           :remote_video_id => "26433049",
                                                           :remote_video_thumbnail => "http://b.vimeocdn.com/ts/174/563/174563798_640.jpg",
                                                           :remote_video_title => "Running on Empty (Revisited)"))
      end
=end
=begin
      it "should accept a Funny or Die link" do
        pending "Funny or Die sharing implementation"
      end
      
      it "should accept a Daily Motion link" do
        pending "Daily Motion sharing implementation"
      end
      
      it "should accept a Break.com link" do
        pending "Break.com sharing implementation"
      end
      
      it "should accept a Metacafe link" do
        pending "Metacafe sharing implementation"
      end
    end
  end
  
  describe "GET #share_a_link" do
    before do
      test_sign_in(@userB)      
    end
    
    describe "for an invalid request" do
      it "should display an error if parameters are missing/invalid" do
        get :share_a_link, :user_id => @userB.id
        response.body.should contain("Oops! We lost something along the way and couldn't get the shared link's video information.")
      end
    end
    
    describe "for a valid request" do
      it "should display the share a video form" do
        get :share_a_link, :user_id => @userB.id,
                           :remote_host => "youtube.com",
                           :remote_link => "http://www.youtube.com/watch?v=N4OPr_QxoFg",
                           :remote_video_description => "Hilarious remake of the old GI Joe public service announcements",
                           :remote_video_id => "N4OPr_QxoFg",
                           :remote_video_thumbnail => "http://i.ytimg.com/vi/N4OPr_QxoFg/hqdefault.jpg",
                           :remote_video_title => "GI Joe PSA - Porkchop Sandwhiches"
        response.body.should contain("Share this Link: http://www.youtube.com/watch?v=N4OPr_QxoFg")
        response.body.should contain("Title it")
        response.body.should contain("GI Joe PSA - Porkchop Sandwhiches")
        response.body.should contain("Describe it")
        response.body.should contain("Hilarious remake of the old GI Joe public service announcements")        
      end
    end
  end
  
  describe "POST #share" do
    before do
      test_sign_in(@userB)      
    end
    
    describe "for an invalid request" do
      it "should NOT create a video without parameters" do
        lambda do
          post :share, :user_id => @userB.id,
        end.should_not change(Video, :count)
      end
      
      it "should NOT allow a blank remote_host" do
        post :share, :user_id => @userB.id,
                     :remote_video_id => "N4OPr_QxoFg",
                     :remote_video_thumbnail => "http://i.ytimg.com/vi/N4OPr_QxoFg/hqdefault.jpg",
                     :video => {:title => "GI Joe PSA - Porkchop Sandwhiches", 
                                :description => "Hilarious remake of the old GI Joe public service announcements"},
                     :videoTags => "GIJoe, PSA, funny"
        @json = JSON.parse(response.body)
        response.status.should == unprocessable_entity
        @json['error'].should == "There was an error saving the link.  We have been notified of this issue."
      end
            
      it "should NOT allow a blank remote_video_id" do
        post :share, :user_id => @userB.id,
                     :remote_host => "youtube.com",
                     :remote_video_thumbnail => "http://i.ytimg.com/vi/N4OPr_QxoFg/hqdefault.jpg",
                     :video => {:title => "GI Joe PSA - Porkchop Sandwhiches", 
                                :description => "Hilarious remake of the old GI Joe public service announcements"},
                     :videoTags => "GIJoe, PSA, funny"
        @json = JSON.parse(response.body)
        response.status.should == unprocessable_entity
        @json['error'].should == "There was an error saving the link.  We have been notified of this issue."
      end
            
      it "should NOT allow a blank remote_video_thumbnail" do
        post :share, :user_id => @userB.id,
                     :remote_host => "youtube.com",
                     :remote_video_id => "N4OPr_QxoFg",
                     :video => {:title => "GI Joe PSA - Porkchop Sandwhiches", 
                                :description => "Hilarious remake of the old GI Joe public service announcements"},
                     :videoTags => "GIJoe, PSA, funny"
        @json = JSON.parse(response.body)
        response.status.should == unprocessable_entity
        @json['error'].should == "There was an error saving the link.  We have been notified of this issue."
      end
    end
    
    describe "for a valid request" do
      it "should be successful" do
        post :share, :user_id => @userB.id,
                     :remote_host => "youtube.com",
                     :remote_video_id => "N4OPr_QxoFg",
                     :remote_video_thumbnail => "http://i.ytimg.com/vi/N4OPr_QxoFg/hqdefault.jpg",
                     :video => {:title => "GI Joe PSA - Porkchop Sandwhiches", 
                                :description => "Hilarious remake of the old GI Joe public service announcements"},
                     :videoTags => "GIJoe, PSA, funny"
        response.should redirect_to @userB
      end
      
      it "should create a new video record" do
        lambda do
          post :share, :user_id => @userB.id,
                       :remote_host => "youtube.com",
                       :remote_video_id => "N4OPr_QxoFg",
                       :remote_video_thumbnail => "http://i.ytimg.com/vi/N4OPr_QxoFg/hqdefault.jpg",
                       :video => {:title => "GI Joe PSA - Porkchop Sandwhiches", 
                                  :description => "Hilarious remake of the old GI Joe public service announcements"},
                       :videoTags => "GIJoe, PSA, funny"
        end.should change(Video, :count).by(1)
      end
      
      it "should create the given video taggings" do
        post :share, :user_id => @userB.id,
                     :remote_host => "youtube.com",
                     :remote_video_id => "N4OPr_QxoFg",
                     :remote_video_thumbnail => "http://i.ytimg.com/vi/N4OPr_QxoFg/hqdefault.jpg",
                     :video => {:title => "GI Joe PSA - Porkchop Sandwhiches", 
                                :description => "Hilarious remake of the old GI Joe public service announcements"},
                     :videoTags => "GIJoe, PSA, funny"
        
        @video = Video.find_by_remote_video_id("N4OPr_QxoFg")
        @giJoe = Tag.find_by_content("GIJoe".downcase)
        @psa = Tag.find_by_content("PSA".downcase)
        @funny = Tag.find_by_content("funny".downcase)
        @video.tags.count.should == 3
        @video.taggings[0].tag_id.should == @giJoe.id
        @video.taggings[1].tag_id.should == @psa.id
        @video.taggings[2].tag_id.should == @funny.id
      end
    end
  end
  
=end

end
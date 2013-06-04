require 'spec_helper'

describe PublicVideosController do
  render_views
  
  before do
    @marketing_user = FactoryGirl.create(:user, :email => "marketing@brevidy.com")
    @video ||= FactoryGirl.create(:video, :title => "I am a public video!")
    @user ||= test_get_object_owner(@video)
    test_sign_in(@user)
    
    # create meta data
    @userB ||= FactoryGirl.create(:user)
    @userB.follow!(@user)
    comment = @video.comments.new(:content => "yay")
    comment.user_id = @userB.id
    comment.save
    @icon ||= FactoryGirl.create(:icon)
    badge = @video.badges.new(:badge_type => @icon.id)
    badge.badge_from = @userB.id
    badge.save
  end
  
=begin
  describe "GET #show" do
    context "for a valid request" do
      context "when the user is signed in" do
        it "should redirect a signed in user to the video#show action" do
          get :show, :public_token => @video.public_token
          response.should redirect_to(user_video_path(@user, @video))
        end
      end
      context "when the users is not signed in" do
        before do
          test_sign_out
          get :show, :public_token => @video.public_token
        end
        it "should render the public page" do
          response.should render_template('public_videos/show')
        end
        it "should not allow search engine crawlers to index the page or follow links on the page" do
          response.body.should =~ /<meta content='noindex, nofollow' name='robots'>/
        end
        it "should contain Facebook's OpenGraph meta tags" do
          response.body.should =~ /<meta content='247345075276137' property='fb:page_id'>/
          response.body.should =~ /<meta content='#{@video.title}' property='og:title'>/
          response.body.should =~ /<meta content='#{@video.get_thumbnail_url(@video.selected_thumbnail)}' property='og:image'>/
          response.body.should =~ /<meta content='Brevidy' property='og:site_name'>/
          response.body.should =~ /<meta content='#{@video.description}' property='og:description'>/
        end  
        it "should show the video's title" do
          response.should have_selector('div.title p', :content => @video.title)
        end
        it "should show the video player" do
          response.should have_selector('div.player')
        end
        it "should show the video owner's photo" do
          response.should have_selector('div.profile_photo img')
        end
        it "should show the user's name and meta data" do
          response.should have_selector('div.user_meta h2', :content => @user.name.downcase)
          response.should contain("#{@user.videos_count} VIDEO")
          response.should contain("#{@user.badges_count_viewable_by(@user)} BADGE")
          response.should contain("#{@user.followers_count_viewable_by(@user)} FOLLOWER")
        end
        it "should have a section describing Brevidy with a link to join now" do
          response.should contain("#{@user.name} is using Brevidy - a way to capture the fleeting moments of your life on video and share them with those around you")
          response.should have_selector('a', :content => "Join now")
        end
        it "should show the video's description" do
          response.should have_selector('div.description p.heading', :content => "DESCRIPTION")
          response.should have_selector('div.description p.content', :content => @video.description)
        end
        it "should show the video's badges" do
          response.should have_selector('div.badges p.heading', :content => "BADGES (#{@video.badges_count_viewable_by(@user)})")
          response.should have_selector('li.badge')
        end
        it "should show the video's comments" do
          response.should have_selector('div.comments p.heading', :content => "COMMENTS (#{@video.get_all_comments_viewable_by(@user).size})")
          response.should have_selector('li.user_comment')
        end
        it "should show a sales blurb for non-members" do
          response.should contain("NOT A MEMBER OF BREVIDY? CLICK HERE TO JOIN!")
        end
        it "should show buttons for social sharing" do
          response.should have_selector('div.social_buttons')
          response.body.should =~ /tweet_button/
          response.body.should =~ /plusone/
          response.body.should =~ /like.php/
        end
      end
    end
    context "for an invalid request" do
      it "should redirect the user to an error page if the public_token was invalid" do
        get :show, :public_token => "bad token"
        response.should render_template('errors/error_404')
      end
      it "should redirect the user to an error page if the video is not in a READY state" do
        @video.set_status(VideoGraph::TRANSCODING)
        @video.save
        
        get :show, :public_token => "bad token"
        response.should render_template('errors/error_404')
      end
    end
  end
=end
end
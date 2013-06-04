require 'spec_helper'

describe TagsController do
  render_views
  
  before do
    @user ||= FactoryGirl.create(:user)
    test_sign_in(@user)
    @tagging ||= FactoryGirl.create(:tagging)
    @tag ||= test_get_tag_from_tagging(@tagging)
  end
  
  describe "DELETE #destroy" do
    before do
      @video = FactoryGirl.create(:video)
      @video_owner = test_get_object_owner(@video)
      test_sign_in(@video_owner)
      @user_B = FactoryGirl.create(:user)
    end
    describe "for an invalid request" do
      it "should render a 404 if an associated video is not found" do
        # give it a bad video id
        xhr :post, :destroy, :id => "999999", :video_id => "999999", :username => @video_owner.username
        # not found
        response.status.should == not_found
      end
      it "should not allow User A to destroy a tag on User B's video" do
        # create the tag first by User A (video owner in this case)
        @tag = Tag.create(:content => "new tag")
        tagging = Tagging.new(:tag_id => @tag.id)
        tagging.video_id = @video.id
        tagging.save
        
        # set current user to User B and try to destroy the tag
        # the controller looks within the current user's videos so it shouldn't be found
        test_sign_out
        test_sign_in(@user_B)
        
        xhr :post, :destroy, :id => tagging.id, :video_id => @video.id, :username => @video_owner.username
        # not found
        response.status.should == not_found
      end
      it "should render a 404 if tag is not found" do
        # try to remove a tag on a valid video
        post :destroy, :id => "999999", :video_id => @video.id, :username => @user_B.username
        # not found
        response.status.should == not_found
      end
    end
    describe "for a valid request" do
      before do
        # create the tag first by User A (video owner in this case)
        @tag = Tag.create(:content => "new tag")
        tagging = Tagging.new(:tag_id => @tag.id)
        tagging.video_id = @video.id
        tagging.save
        # destroy the tagging relationship
        post :destroy, :id => tagging.id, :video_id => @video.id, :username => @video_owner.username
      end
      it "should remove the tag-video join relationship" do
        # ok
        response.status.should == ok
        # make sure relationship doesn't exist anymore
        @old_tagging = Tagging.where(:video_id => @video.id, :tag_id => Tag.find_by_content("new tag")).first
        @old_tagging.should be_nil
      end
      it "should not remove the tag" do
        # make sure tag still exists
        @original_tag = Tag.find_by_content("new tag")
        @original_tag.should_not be_nil
      end
    end
  end
  
end
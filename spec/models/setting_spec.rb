require 'spec_helper'

describe Setting do
  before do
    @user = FactoryGirl.create(:user)
  end
  
  describe "accessible attributes" do
    before do
      @setting = @user.setting
    end
    it "should NOT allow mass-assignment of non-accessible attributes" do
      @setting.should_not allow_mass_assignment_of(:user_id => "999999")
    end
    it "should allow mass-assignment of accessible attributes" do
      @setting.should allow_mass_assignment_of(:hide_getting_started => true)
      @setting.should allow_mass_assignment_of(:send_email_for_new_badges => false)
      @setting.should allow_mass_assignment_of(:send_email_for_new_comments => false)
      @setting.should allow_mass_assignment_of(:send_email_for_replies_to_a_prior_comment => false)
      @setting.should allow_mass_assignment_of(:send_email_for_new_subscriber => false)
      @setting.should allow_mass_assignment_of(:send_email_for_featured_video => false)
      @setting.should allow_mass_assignment_of(:send_email_for_private_channel_request => false)
      @setting.should allow_mass_assignment_of(:send_email_for_encoding_completion => false)
    end
  end
  
  describe "for a valid request" do
    it "should save successfully" do
      setting = Setting.new
      setting.user_id = @user.id
      setting.save
      setting.should be_valid
    end
  end
  describe "for an invalid request" do
    it "should not save without a user_id" do
      setting = Setting.new
      setting.user_id = nil
      setting.save
      setting.should_not be_valid
    end
    it "should only accept true/false for boolean attributes" do
      setting = Setting.new
      setting.user_id = @user.id
      setting.save
      setting.should be_valid
      
      # toggle each boolean attribute and make sure it is false
      # (which is what happens by default for bad values)
      the_attributes = %w(hide_getting_started send_email_for_new_badges send_email_for_new_comments 
                          send_email_for_replies_to_a_prior_comment send_email_for_new_subscriber send_email_for_featured_video
                          send_email_for_private_channel_request send_email_for_encoding_completion)

      the_attributes.each do |ta|
        setting.update_attribute(ta, "bad boolean")
        setting.save
        setting.send(ta).should be_false
      end
    end
  end
end













# == Schema Information
#
# Table name: settings
#
#  id                                        :integer         not null, primary key
#  created_at                                :datetime
#  updated_at                                :datetime
#  user_id                                   :integer
#  hide_getting_started                      :boolean         default(FALSE)
#  send_email_for_new_badges                 :boolean         default(TRUE)
#  send_email_for_new_comments               :boolean         default(TRUE)
#  send_email_for_replies_to_a_prior_comment :boolean         default(TRUE)
#  send_email_for_new_subscriber             :boolean         default(TRUE)
#  send_email_for_featured_video             :boolean         default(TRUE)
#  send_email_for_private_channel_request    :boolean         default(TRUE)
#  send_email_for_encoding_completion        :boolean         default(TRUE)
#


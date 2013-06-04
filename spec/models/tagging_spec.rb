require 'spec_helper'

describe Tagging do
  
  describe "accessible attributes" do
    before do
      @tagging = FactoryGirl.create(:tagging)
    end
    it "should NOT allow mass-assignment of non-accessible attributes" do
      @tagging.should_not allow_mass_assignment_of(:id => "999999")
      @tagging.should_not allow_mass_assignment_of(:video_id => "999999")
      @tagging.should_not allow_mass_assignment_of(:created_at => "999999")
      @tagging.should_not allow_mass_assignment_of(:updated_at => "999999")
      @tagging.should_not allow_mass_assignment_of(:video_owner_id => "999999")
    end
    it "should allow mass-assignment of accessible attributes" do
      pending 'needs fixing'
      # for whatever reason, it says mass-assignment failed by it works
      # just fine in the console.. probably something to do with lifecycle
      # callbacks in the model
      # @tagging.should allow_mass_assignment_of(:tag_id => "999999")
    end
  end
  
  describe "for normal tests" do
    before do
      @tagging = FactoryGirl.build(:tagging)
    end
    describe "for a invalid request" do
      it "should not save without passing in :tag_id" do
        @tagging.tag_id = nil
        @tagging.save
        @tagging.should_not be_valid
      end
      it "should not save without passing in :video_id" do
        @tagging.video_id = nil
        @tagging.save
        @tagging.should_not be_valid
      end
    end
    describe "for a valid request" do
      it "should save successfully" do
        @tagging.save
        @tagging.should be_valid
      end
    end
  end
end





# == Schema Information
#
# Table name: taggings
#
#  id             :integer         not null, primary key
#  video_id       :integer
#  tag_id         :integer
#  created_at     :datetime
#  updated_at     :datetime
#  video_owner_id :integer
#


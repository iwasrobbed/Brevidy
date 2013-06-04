require 'spec_helper'

describe Blocking do
  before do
    @user = FactoryGirl.create(:user)
    @userB = FactoryGirl.create(:user)
  end
  
  describe "accessible attributes" do
    it "should NOT allow mass-assignment of non-accessible attributes" do
      blocking = Blocking.new
      blocking.requesting_user = @user.id
      blocking.blocked_user = @userB.id
      blocking.save
      blocking.should be_valid
      
      blocking.should_not allow_mass_assignment_of(:requesting_user => "999999")
      blocking.should_not allow_mass_assignment_of(:blocked_user => "999999")
    end
  end
  
  describe "for an invalid request" do
    it "should not save without passing in :requesting_user" do
      blocking = Blocking.new
      blocking.requesting_user = nil
      blocking.blocked_user = @userB.id
      blocking.save
      
      blocking.should_not be_valid
    end
    it "should not save without passing in :blocked_user" do
      blocking = Blocking.new
      blocking.requesting_user = @user.id
      blocking.blocked_user = nil
      blocking.save
      
      blocking.should_not be_valid
    end
  end
  describe "for a valid request" do
    it "should save properly" do
      blocking = Blocking.new
      blocking.requesting_user = @user.id
      blocking.blocked_user = @userB.id
      blocking.save

      blocking.should be_valid
    end
  end
end



# == Schema Information
#
# Table name: blockings
#
#  id              :integer         not null, primary key
#  requesting_user :integer
#  blocked_user    :integer
#  created_at      :datetime
#  updated_at      :datetime
#


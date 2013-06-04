require 'spec_helper'

describe BannedUser do
  it "should require an email address" do
    banned_user = BannedUser.create(:email => nil,
                                    :reason => "Something",
                                    :detailed_reason => "Something something")
    banned_user.should_not be_valid
  end
  it "should require a reason" do
    banned_user = BannedUser.create(:email => "banned@brevidy.com",
                                    :reason => nil,
                                    :detailed_reason => "Something something")
    banned_user.should_not be_valid
  end
  it "should require a detailed reason" do
    banned_user = BannedUser.create(:email => "banned@brevidy.com",
                                    :reason => "Something",
                                    :detailed_reason => nil)
    banned_user.should_not be_valid
  end
  it "should be successful for a valid model" do
    banned_user = BannedUser.create(:email => "banned@brevidy.com",
                                    :reason => "Something",
                                    :detailed_reason => "Something something")
    banned_user.should be_valid
  end
end




# == Schema Information
#
# Table name: banned_users
#
#  id              :integer         not null, primary key
#  email           :string(255)
#  reason          :text
#  created_at      :datetime
#  updated_at      :datetime
#  detailed_reason :text
#


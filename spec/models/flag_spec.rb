require 'spec_helper'

describe Flag do
  describe "accessible attributes" do
    before do
      @flag = Flag.create(:reason => "Help")
    end
    it "should allow mass-assignment of accessible attributes" do
      @flag.should allow_mass_assignment_of(:reason => "Other help")
    end
  end
  it "should require a reason" do
    flag = Flag.create(:reason => nil)
    flag.should_not be_valid
  end
end



# == Schema Information
#
# Table name: flags
#
#  id         :integer         not null, primary key
#  reason     :string(255)
#  created_at :datetime
#  updated_at :datetime
#


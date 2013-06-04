require 'spec_helper'

describe Tag do
  describe "accessible attributes" do
    before do
      @tag = FactoryGirl.create(:tag)
    end
    
    it "should NOT allow mass-assignment of non-accessible attributes" do
      @tag.should_not allow_mass_assignment_of(:id => "999999")
      @tag.should_not allow_mass_assignment_of(:created_at => "999999")
      @tag.should_not allow_mass_assignment_of(:updated_at => "999999")
    end
    it "should allow mass-assignment of accessible attributes" do
      @tag.should allow_mass_assignment_of(:content => "other content")
    end
  end
  
  it "should not save without passing in :content" do
    tag = Tag.create(:content => nil)
    tag.should_not be_valid
  end
  it "should not save a tag longer than 250 characters" do
    tag_content = "a" * 251
    tag = Tag.create(:content => tag_content)
    tag.should_not be_valid
  end
  
end



# == Schema Information
#
# Table name: tags
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  content    :string(255)
#


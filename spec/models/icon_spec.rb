require 'spec_helper'

describe Icon do
  describe "for an invalid request" do
    it "should not save without passing in :icon_type" do
      icon = Icon.create(:name => "Test", 
                         :icon_type => nil, 
                         :css_class => "badgeTest",
                         :active => true)
      icon.should_not be_valid
    end
    it "should not save without passing in :name" do
      icon = Icon.create(:name => nil, 
                         :icon_type => "badge", 
                         :css_class => "badgeTest",
                         :active => true)
      icon.should_not be_valid
    end
    it ":active should be false if :active is passed in as something other than true / false" do
      icon = Icon.create(:name => "Test", 
                         :icon_type => "badge", 
                         :css_class => "badgeTest",
                         :active => "poop")
      icon.should be_valid
      icon.active.should be_false
    end
    it "should not save if :active is passed in as nil" do
      icon = Icon.create(:name => "Test", 
                         :icon_type => "badge", 
                         :css_class => "badgeTest",
                         :active => nil)
      icon.should_not be_valid
    end
  end
  describe "for a valid request" do
    it "does not need the optional :css_class field" do
      icon = Icon.create(:name => "Test", 
                         :icon_type => "bagde", 
                         :css_class => nil,
                         :active => true)
      icon.should be_valid
    end
    it "should save properly" do
      icon = Icon.create(:name => "Test", 
                         :icon_type => "badge", 
                         :css_class => "badgeTest",
                         :active => true)
      icon.should be_valid
    end
  end
end



# == Schema Information
#
# Table name: icons
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  css_class  :string(255)
#  active     :boolean
#  created_at :datetime
#  updated_at :datetime
#  icon_type  :string(255)
#


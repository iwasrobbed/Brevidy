require 'spec_helper'

describe Channel do
  before do
    @channel ||= FactoryGirl.create(:channel)
    @channel_owner = @channel.user
  end
  
  describe "protected attributes" do
    it "should not allow mass-assignment" do
      @channel.should_not allow_mass_assignment_of(:user_id => 999999)
      @channel.should_not allow_mass_assignment_of(:private => true)
      @channel.should_not allow_mass_assignment_of(:featured => true)
      @channel.should_not allow_mass_assignment_of(:recommended => true)
      @channel.should_not allow_mass_assignment_of(:public_token => "asdf1234")
    end
    it "should allow mass-assignment of whitelisted attributes" do
      @channel.should allow_mass_assignment_of(:title => "yayyyyyyyy")
    end
  end
  
  describe "lifecycle actions" do
    it "should not let the user destroy a featured channel" do
      @channel.update_attribute(:featured, true)
      lambda do
        @channel.destroy
      end.should_not change(Channel, :count).by(-1)
    end
    it "should generate a public token" do
      @channel.public_token.should_not be_nil
    end
    it "should strip whitespace from the title" do
      @channel.title = "   Some New Title   "
      @channel.save
      @channel.reload
      @channel.title.should == "Some New Title"
    end
  end
  
  describe "validations" do
    it "should require a title" do
      @channel.title = nil
      @channel.save
      @channel.should_not be_valid
      @channel.errors['title'].should_not be_empty
    end
    it "should not allow long titles" do
      @channel.title = "a" * 31
      @channel.save
      @channel.should_not be_valid
      @channel.errors['title'].should_not be_empty
    end
    it "should not allow the user to have multiple channels with the same title (regardless of char case or whitespace)" do
      @new_channel = FactoryGirl.build(:channel, :user_id => @channel.user_id, :title => @channel.title)
      @new_channel.save
      @new_channel.should_not be_valid
      @new_channel.errors['title'].should_not be_empty
      
      # check the case sensitive version
      @new_channel = FactoryGirl.build(:channel, :user_id => @channel.user_id, :title => "My new channel")
      @new_channel.save
      @new_channel.should be_valid
      @new_channel.errors['title'].should be_empty
      
      @new_channel = FactoryGirl.build(:channel, :user_id => @channel.user_id, :title => "   mY neW ChANneL      ")
      @new_channel.save
      @new_channel.should_not be_valid
      @new_channel.errors['title'].should_not be_empty
    end
    it "should not let the user make the featured channel private" do
      @channel.update_attribute(:featured, true)
      @channel.private = true
      @channel.save
      @channel.should_not be_valid
      @channel.errors['private'].should_not be_empty
    end
    it "should not let the user change the title for a featured channel" do
      @channel.update_attribute(:featured, true)
      @channel.title = "New title"
      @channel.save
      @channel.should_not be_valid
      @channel.errors['title'].should_not be_empty
    end
    it "should require a public_token unless it's a featured channel" do
      @channel.public_token = nil
      @channel.save
      @channel.should_not be_valid
      @channel.errors['public_token'].should_not be_empty
      
      @featured_channel = @channel_owner.channels.where(:featured => true).first
      @featured_channel.public_token = nil
      @featured_channel.save
      @featured_channel.should be_valid
      @featured_channel.errors['public_token'].should be_empty
    end
  end
  
end


# == Schema Information
#
# Table name: channels
#
#  id           :integer         not null, primary key
#  user_id      :integer
#  title        :string(255)
#  private      :boolean         default(FALSE)
#  featured     :boolean         default(FALSE)
#  created_at   :datetime
#  updated_at   :datetime
#  public_token :string(255)
#  recommended  :boolean         default(FALSE)
#


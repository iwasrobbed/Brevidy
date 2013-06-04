require 'spec_helper'

describe User do  
  
  describe "for invalid attributes" do
    it "should require a username" do
      no_username_user = FactoryGirl.build(:user, :username => "")
      no_username_user.save
      no_username_user.should_not be_valid
    end
    
    it "should reject usernames that are too long" do
      long_username = "a" * 21
      long_username_user = FactoryGirl.build(:user, :username => long_username)
      long_username_user.save
      long_username_user.should_not be_valid
    end
    
    it "should reject usernames that don't match the regex @ http://rubular.com/r/PiP1nTNph2" do
      bad_usernames = ["hi_there jh", "98_scores", "_98_a", "__donkeys", "donk__keys", "@aksdj", "_"]
      bad_usernames.each do |bad_username|
        bad_username_user = FactoryGirl.build(:user, :username => bad_username)
        bad_username_user.save
        bad_username_user.should_not be_valid
      end
    end
    
    it "should require a name" do
      no_name_user = FactoryGirl.build(:user, :name => "")
      no_name_user.save
      no_name_user.should_not be_valid
    end
    
    it "should reject names that are too long" do
      long_name = "a" * 31
      long_name_user = FactoryGirl.build(:user, :name => long_name)
      long_name_user.save
      long_name_user.should_not be_valid
    end
    
    it "should reject names with invalid characters" do
      bad_names = %w[TeenieBopper16 Dr*(012809poop hax0r]
      bad_names.each do |bad_name|
        bad_name_user = FactoryGirl.build(:user, :name => bad_name)
        bad_name_user.save
        bad_name_user.should_not be_valid
      end
    end
    
    it "should reject locations that are too long" do
      long_location_name = "a" * 51
      long_location_name_user = FactoryGirl.build(:user, :location => long_location_name)
      long_location_name_user.save
      long_location_name_user.should_not be_valid
    end

    it "should require an email address" do
      no_email_user = FactoryGirl.build(:user, :email => "")
      no_email_user.save
      no_email_user.should_not be_valid
    end
    
    it "should reject emails that are too long" do
      long_email = "a" * 239 + "@brevidy.com"
      long_email_user = FactoryGirl.build(:user, :email => long_email)
      long_email_user.save
      long_email_user.should_not be_valid
    end
    
    it "should reject invalid email addresses" do
      addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
      addresses.each do |address|
        invalid_email_user = FactoryGirl.build(:user, :email => address)
        invalid_email_user.save
        invalid_email_user.should_not be_valid
      end
    end
    
    it "should reject duplicate email addresses" do
      FactoryGirl.create(:user, :email => "johnny@brevidy.com")
      user_with_duplicate_email = FactoryGirl.build(:user, :email => "johnny@brevidy.com")
      user_with_duplicate_email.save
      user_with_duplicate_email.should_not be_valid
    end

    it "should reject identical email addresses that differ by their cAsE" do
      upcased_email = "johnny@brevidy.com".upcase
      FactoryGirl.create(:user, :email => upcased_email)
      user_with_duplicate_email = FactoryGirl.build(:user, :email => "johnny@brevidy.com")
      user_with_duplicate_email.save
      user_with_duplicate_email.should_not be_valid
    end
    
    it "should reject email addresses that have been banned" do
      banned_user = FactoryGirl.build(:user, :email => "banned@brevidy.com")
      BannedUser.create(:email => banned_user.email, 
                        :reason => "Test",
                        :detailed_reason => "Test test")
      banned_user.save
      banned_user.should_not be_valid
    end
    
    it "should require a password" do
      no_password_user = FactoryGirl.build(:user, :password => "")
      no_password_user.save
      no_password_user.should_not be_valid
    end
    
    it "should reject short passwords" do
      short = "a" * 5
      short_password_user = FactoryGirl.build(:user, :password => short)
      short_password_user.save
      short_password_user.should_not be_valid
    end
    
    it "should reject really, really long passwords that exceed a string size" do
      long = "a" * 251
      long_password_user = FactoryGirl.build(:user, :password => long)
      long_password_user.save
      long_password_user.should_not be_valid
    end
    
    it "should reject incorrect genders" do
      bad_gender_user = FactoryGirl.build(:user, :gender => "Confused")
      bad_gender_user.save
      bad_gender_user.should_not be_valid
    end
    
    it "should require a birthday" do
      no_birthday_user = FactoryGirl.build(:user, :birthday => "")
      no_birthday_user.save
      no_birthday_user.should_not be_valid
    end
    
    it "should reject invalid birthdays" do
      bad_birthday_user = FactoryGirl.build(:user, :birthday => "bad date format")
      bad_birthday_user.save
      bad_birthday_user.should_not be_valid
    end
  end
  
  describe "for valid attributes" do
    it "should create a new user" do
      FactoryGirl.create(:user)
    end

    it "should accept usernames that are correct length" do
      long_username = "a" * 20
      long_username_user = FactoryGirl.build(:user, :username => long_username)
      long_username_user.save
      long_username_user.should be_valid
    end
    
    it "should accept usernames that match the regex @ http://rubular.com/r/PiP1nTNph2" do
      good_usernames = ["Hi_There", "_a_98", "_hi_there", "something_", "some_on_01", "a", "_donkeys", "_p"]
      good_usernames.each do |good_username|
        good_username_user = FactoryGirl.build(:user, :username => good_username)
        good_username_user.save
        good_username_user.should be_valid
      end
    end
    
    it "should not require a gender" do
      no_gender_user = FactoryGirl.build(:user, :gender => "")
      no_gender_user.save
      no_gender_user.should be_valid
    end
    
    it "should create a profile associated with that user" do
      user = FactoryGirl.create(:user)
      profile = Profile.find_by_user_id(user.id)
      profile.should_not be_nil 
    end
    
    it "should create default settings for that user" do
      user = FactoryGirl.create(:user)
      settings = Setting.find_by_user_id(user.id)
      settings.should_not be_nil
    end
    
    it "should accept names with valid characters" do
      good_names = %w[Dr.Phil ShayO'Donnel Fred]
      good_names.each do |good_name|
        good_name_user = FactoryGirl.build(:user, :name => good_name)
        good_name_user.save
        good_name_user.should be_valid
      end
    end
    
    it "should accept valid email addresses" do
      addresses = %w[user@brevidy.com THE_USER@brevidy.bar.org first.last@brevidy.co.jp]
      addresses.each do |address|
        valid_email_user = FactoryGirl.create(:user, :email => address)
        valid_email_user.should be_valid
      end
    end
    
    it "should have a password attribute" do
      FactoryGirl.create(:user).should respond_to(:password)
    end
    
    it "should ensure the user is older than 13 years old" do
      too_young_user = FactoryGirl.build(:user, :birthday => 12.years.ago)
      too_young_user.save
      too_young_user.should_not be_valid
    end
    
    it "should trim whitespace around names, emails, and usernames and downcase email and usernames" do
      whitespaced_user = FactoryGirl.build(:user)
      whitespaced_user.name = "   Rob   "
      whitespaced_user.email = "   uSeR@bReViDy.cOm   "
      whitespaced_user.username = "   sOmEuSeRhErE   "
      whitespaced_user.save
      whitespaced_user.name.should == "Rob"
      whitespaced_user.email.should == "user@brevidy.com"
      whitespaced_user.username = "someuserhere"
    end
  end
  
  describe "background image handling" do
    before do
      @user = FactoryGirl.create(:user)
    end
    it "should not let the user set a background_image_id of anything but 0 or 1" do
      @user.background_image_id = 0
      @user.save
      @user.reload
      @user.background_image_id.should == 0
      
      @user.background_image_id = 1
      @user.save
      @user.reload
      @user.background_image_id.should == 1
      
      @user.background_image_id = 2
      @user.save
      @user.reload
      @user.background_image_id.should_not == 2
    end
  end
  
  describe "username handling" do
    before do
      @user = FactoryGirl.create(:user)
    end
    it "should not let the user change their username more than once a month" do
      @user.username = "username_no_2"
      @user.save
      @user.reload
      @user.username.should == "username_no_2"
      
      # controller takes care of setting timestamp, so we'll just mock it here
      @user.username_changed_at = DateTime.now
      @user.save
      
      # now try it again
      @user.username = "username_no_3"
      @user.save
      @user.reload
      @user.username.should_not == "username_no_3"
    end
  end
  
  describe "password encryption and authentication" do
  
    before(:each) do
      @user = FactoryGirl.create(:user, :email => "johnny@brevidy.com", :password => "apples")
    end

    describe "password encryption" do
      it "should be a private method" do
        User.should_not respond_to(:encrypt_password)
      end
      
      it "should set the password attribute" do
        @user.password.should_not be_blank
      end

      it "should have a salt" do
        @user.should respond_to(:salt)
      end
    end

    describe "has_password? method" do
      it "should exist" do
        @user.should respond_to(:has_password?)
      end

      it "should return true if the passwords match" do
        @user.has_password?("apples").should be_true
      end
      
      it "should return false if the passwords don't match" do
        @user.has_password?("invalid_password").should be_false
      end
    end
    
    describe "authenticate method" do
      it "should exist" do
        User.should respond_to(:authenticate)
      end
      
      it "should return nil on email/password mismatch" do
        User.authenticate("johnny@brevidy.com", "wrongpass").should be_nil
      end
      
      it "should return nil for an email address with no user" do
        User.authenticate("wrong_email@brevidy.com", "apples").should be_nil
      end
      
      it "should return the user on email/password match" do
        User.authenticate("johnny@brevidy.com", "apples").should == @user
      end
    end
  end
  
end




# == Schema Information
#
# Table name: users
#
#  id                  :integer         not null, primary key
#  email               :string(255)
#  password            :string(255)
#  salt                :string(255)
#  name                :string(255)
#  image               :string(255)
#  birthday            :date
#  gender              :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  location            :string(255)
#  reset_token         :string(255)
#  pw_reset_timestamp  :datetime
#  image_status        :string(255)
#  is_deactivated      :boolean         default(FALSE)
#  delta               :boolean         default(TRUE), not null
#  username            :string(255)
#  banner_image        :string(255)
#  banner_image_id     :integer         default(1)
#  username_changed_at :datetime
#  background_image_id :integer         default(0)
#


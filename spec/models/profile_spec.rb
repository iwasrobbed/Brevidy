require 'spec_helper'

describe Profile do
  it "should not save without passing in :user_id" do
    profile = Profile.new
    profile.user_id = nil
    profile.should_not be_valid
  end
  describe "for optional information" do
    before do
      user = FactoryGirl.create(:user)
      @profile = user.profile
      @categories = %w{website bio interests favorite_music favorite_movies favorite_books favorite_foods 
       favorite_people things_i_could_live_without one_thing_i_would_change_in_the_world
       quotes_to_live_by}
    end
    it "should save all categories if valid" do
      @categories.each do |c|
        # ensure the attribute is nil before we populate it
        @profile.attributes[c].should be_nil
        # now write a string to it
        if c == 'quotes_to_live_by'
          @profile.update_attributes(c => "a" * 3000)
        elsif c == 'website'
          @profile.update_attributes(c => "http://" + "a" * 243)
        elsif c == 'bio'
          @profile.update_attributes(c => "a" * 140)
        else
          @profile.update_attributes(c => "a" * 1000)
        end
        @profile.save
        @profile.errors[c].should be_empty
      end
    end
    it "should NOT save all categories if there are too many characters" do
      @categories.each do |c|
        # ensure the attribute is nil before we populate it
        @profile.attributes[c].should be_nil
        # now write a string to it
        if c == 'quotes_to_live_by'
          @profile.update_attributes(c => "a" * 3001)
        elsif c == 'website'
          @profile.update_attributes(c => "http://" + "a" * 244)
        elsif c == 'bio'
          @profile.update_attributes(c => "a" * 141)
        else
          @profile.update_attributes(c => "a" * 1001)
        end
        @profile.save
        @profile.errors[c].should_not be_empty
      end
    end
  end
end





# == Schema Information
#
# Table name: profiles
#
#  id                                    :integer         not null, primary key
#  user_id                               :integer
#  interests                             :text
#  favorite_music                        :text
#  favorite_movies                       :text
#  favorite_books                        :text
#  favorite_people                       :text
#  things_i_could_live_without           :text
#  one_thing_i_would_change_in_the_world :text
#  quotes_to_live_by                     :text
#  created_at                            :datetime
#  updated_at                            :datetime
#  favorite_foods                        :text
#  bio                                   :string(255)
#  website                               :string(255)
#


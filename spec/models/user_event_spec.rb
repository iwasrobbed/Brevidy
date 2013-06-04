require 'spec_helper'

describe UserEvent do
  before do
    @user ||= FactoryGirl.create(:user)
    @event_creator ||= FactoryGirl.create(:user)
  end
  it "should require an event_type" do
    bad_user_event = UserEvent.new(:event_type => nil,
                                   :event_object_id => 1,
                                   :user_id => @user.id,
                                   :event_creator_id => @event_creator.id)
    bad_user_event.save
    bad_user_event.should_not be_valid
  end
  it "should require an event_object_id" do
    bad_user_event = UserEvent.new(:event_type => 1,
                                   :event_object_id => nil,
                                   :user_id => @user.id,
                                   :event_creator_id => @event_creator.id)
    bad_user_event.save
    bad_user_event.should_not be_valid
  end
  it "should require a user_id" do
    bad_user_event = UserEvent.new(:event_type => 1,
                                   :event_object_id => 1,
                                   :user_id => nil,
                                   :event_creator_id => @event_creator.id)
    bad_user_event.save
    bad_user_event.should_not be_valid
  end
  it "should require an event_creator_id" do
    bad_user_event = UserEvent.new(:event_type => 1,
                                   :event_object_id => 1,
                                   :user_id => @user.id,
                                   :event_creator_id => nil)
    bad_user_event.save
    bad_user_event.should_not be_valid
  end
  it "should save if all fields are present" do
    good_user_event = UserEvent.new(:event_type => 1,
                                    :event_object_id => 1,
                                    :user_id => @user.id,
                                    :event_creator_id => @event_creator.id)
    good_user_event.save
    good_user_event.should be_valid
  end
end







# == Schema Information
#
# Table name: user_events
#
#  id                  :integer         not null, primary key
#  event_type          :integer
#  event_object_id     :integer
#  user_id             :integer
#  created_at          :datetime
#  updated_at          :datetime
#  event_creator_id    :integer
#  error_during_render :boolean         default(FALSE)
#  seen_by_user        :boolean         default(FALSE)
#


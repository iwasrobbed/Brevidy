class UserEvent < ActiveRecord::Base
  # Validations
  validates :event_type, :event_object_id, :user_id, :event_creator_id, :presence => true
  
  # Returns model and event types for a given event
  def get_event_class_type
    case self.event_type
      when UserEvent.event_type_value(:badge)
        model_name = Badge
        event_type = 'badge'   
      when UserEvent.event_type_value(:comment)
        model_name = Comment
        event_type = 'comment'   
      when UserEvent.event_type_value(:comment_response)
        model_name = Comment
        event_type = 'comment_response'
      when UserEvent.event_type_value(:subscription)
        model_name = Subscription
        event_type = 'subscription'        
      when UserEvent.event_type_value(:channel_request)
        model_name = ChannelRequest
        event_type = 'channel_request'        
      else
        false
    end
    
    return [model_name, event_type]
  end
  
  # Instantiates objects based on model type and the object ids
  def get_event_objects(model_name)
    begin
      events_not_associated_with_videos = [UserEvent.event_type_value(:subscription), UserEvent.event_type_value(:channel_request)]
      associated_with_video = !events_not_associated_with_videos.include?(self.event_type)
      model_object = model_name.find(self.event_object_id)
      if associated_with_video 
        video_id = model_object.video_id
        video = Video.find(video_id)
      else
        video = nil
      end
      
      # returns User who created event, Object for event, and Video for event if necessary
      return [User.find_by_id(self.event_creator_id), model_object, video]  
    rescue
      # If there was an error, set the error flag for the UserEvent object
      # and return nil so we don't display that event to the user
      self.update_attributes(:error_during_render => true)
      return nil
    end
  end
  
  class << self
    # Returns an integer for a event type
    # Latest # is 8
    # Prior deleted #'s are: 4, 6
    def event_type_value(event)
      return case event
        when :badge
          1
        when :comment
          2
        when :comment_response
          3
        when :subscription
          5
        when :video_play
          7
        when :channel_request
          8
        else
          false
      end
    end
  end # end self class
    
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


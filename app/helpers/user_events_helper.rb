module UserEventsHelper
  def render_content_for_event(event)    
    event_class ||= event.get_event_class_type
    event_objects ||= event.get_event_objects(event_class[0])

    # Event Objects will be blank if there was an error getting info about that particular event
    unless event_objects.blank?
      # Renders the correct HTML partial given the event info
      render :partial => 'user_events/user_event.html',
             :locals => { :event_type => event_class[1],
                          :object_class => event_objects[1].class,
                          :object => event_objects[1],
                          :user => event_objects[0],
                          :video => event_objects[2],
                          :seen_by_user => event.seen_by_user }
    end
  end    
end
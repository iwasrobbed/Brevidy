module ApplicationHelper
  
  # Generates a cache-buster path for Heroku js and CSS files
  # This will break when we upgrade to Rails 3.1 and should be
  # replaced with asset pipelines
  # See: https://github.com/rails/rails/issues/1258
  def cache_buster_path(path)
    return path << '?' << rails_asset_id(path)
  end
  
  #####################
  ## Sorting Helpers ##
  #####################
  
  # For each icon, look up badge count and put it in array hash along with name and css_class
  def sort_badges_by_count_for_user(badges, the_user)
    sorted_badges = Array.new
    badges.each do |badge|
      sorted_badges << {:name => badge.name, :css_class => badge.css_class, :count => the_user.badges_count_for_type(badge.id)}
    end
    return sorted_badges.sort_by{|bdgs| bdgs[:count]}.reverse
  end
  
  #######################
  ## Ownership Helpers ##
  #######################
	
	# Returns the owner (as a User object) for a given object (comment, video, etc)
  def get_object_owner(object)
    User.find_by_id(object.user_id)
  end
  
  # Returns if the current user owns a given object (comment, video, etc)
  def current_user_owns?(object)
    signed_in? ? object.user_id == current_user.id : false
  end
  
  ####################
  ## Finder Helpers ##
  ####################
  
  # Returns a badge object owned by current user for a given badge type and associated video
  def find_badge_for_video(badge_type, video)
    video.badges.where(:badge_from => current_user, :badge_type => badge_type).first
  end
  
  # Returns a video object given a video ID
  def get_video_by_id(id)
    Video.find_by_id(id)
  end
  
  # Returns all available, active badges
  def get_all_active_badges
    Icon.active.badges.order_by_name
  end
  
  ######################
  ## Standard Helpers ##
  ######################
  
  # Returns whether we should be using a light or dark bg for the user
  def get_background_for_user
    return "light" if current_user.blank? || current_user.background_image_id == 0
    return "dark" if current_user.background_image_id == 1
    # catch all just in case...
    return "light"
  end
  
  # Returns whether or not we should be showing the Facebook OpenGraph meta tags
  def we_should_show_og_tags
    (controller.controller_name == "public_videos" && controller.action_name == "show") ||
    (controller.controller_name == "videos" && controller.action_name == "show")
  end
  
  # Returns whether current users can invite people or not
  def more_people_can_be_invited?
    User::USERS_CAN_INVITE_MORE_PEOPLE
  end
  
  # Returns whether or not to highlight Latest Activity on the left nav
  def highlight_latest_activity?
    controller.controller_name == "user_events" && controller.action_name == "show"
  end
  
  # Check helper for whether or not to show navigation footer items
  def infinite_scrolling_shown?
    @infinite_scrolling_shown
  end
  
  # Defines whether or not to show navigation footer items
  def infinite_scrolling(trueOrNil)
    @infinite_scrolling_shown = trueOrNil
  end
  
  # Builds up all flash and validation error messages into a @flash_msg object
  def compact_flash_messages
    if !flash.empty?
      [:error, :success, :notice, :warning].each do |key| 
        unless flash[key].blank?
          @flash_key = key
          if flash[key].kind_of?(Array) && flash[key].size > 1
            @flash_msg = flash[key].join(' & ')
          elsif flash[key].kind_of?(Array) && flash[key].size == 1
            @flash_msg = flash[key].first
          elsif flash[key].kind_of?(String)
            @flash_msg = flash[key]
          end
        end
      end
    end
    return
  end
  
  # Defines the site-wide Title format
  # Titles are stored in their respective controllers
  def browser_title
    default_title = "Brevidy - The soul of video"
    base_title = "Brevidy"
    if @browser_title.nil?
      default_title
    else
      browser_title = "#{@browser_title} - #{base_title}"
    end
  end
  
end

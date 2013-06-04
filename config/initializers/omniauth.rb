Rails.application.config.middleware.use OmniAuth::Builder do  
  provider :twitter, Brevidy::Application::TWITTER_CONSUMER_KEY, Brevidy::Application::TWITTER_CONSUMER_SECRET
  if Rails.env.production?
    provider :facebook, 'your_key_here', 'your_key_here', 
                        { :scope => "publish_stream, offline_access, email, user_birthday, user_location, user_videos, user_interests" }
  else
    provider :facebook, 'your_key_here', 'your_key_here', 
                        { :scope => "publish_stream, offline_access, email, user_birthday, user_location, user_videos, user_interests" }
  end
end 
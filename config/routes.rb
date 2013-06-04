Brevidy::Application.routes.draw do
  # Domain Route
  root :to => 'users#new'
  
  # Session / Authentication Routes
  resources :sessions, :only => [:create]
  match :login, :to => 'sessions#new'
  match :logout, :to => 'sessions#destroy'
  match :signup, :to => 'users#signup'
  match "/auth/:provider/callback", :to => "sessions#create_social_session"
  match "/auth/failure", :to => "errors#error_social_auth"
  match "/auth/deauthorize", :to => "social_networks#deauthorize"
  match 'account/forgotten_password', :to => 'users#forgotten_password', :as => :forgotten_password, :via => [:get]
  match 'account/validate_forgotten_password', :to => 'users#validate_forgotten_password', :as => :validate_forgotten_password, :via => [:post]
  
  # Explore Routes
  match :explore, :to => 'videos#explore', :via => [:get] # aka the popular videos page
  #match 'explore/suggested_channels', :to => 'videos#suggested_channels', :as => :suggested_channels, :via => [:get]
  #match 'explore/recent', :to => 'videos#recent', :as => :recent_videos, :via => [:get]
  match 'explore/users', :to => 'users#index', :as => :find_people, :via => [:get]
  
  # Invitation Route
  match 'invitations/:invitation_token', :to => 'users#new', :as => :signup_via_invitation, :via => [:get]
  
  # Search Routes
  match 'search/videos', :to => 'search#videos', :as => :video_search, :via => [:get]
  match 'search/users', :to => 'search#users', :as => :user_search, :via => [:get]
  
  # Public Video / Channel Routes
  match 'p/:public_token', :to => 'public_videos#show', :as => :public_video, :via => [:get]
  match 'embed/:public_token', :to => 'public_videos#embed', :as => :embed_video, :via => [:get]
  match 'c/:public_token', :to => 'channels#show_by_token_access', :as => :public_channel, :via => [:get]
  
  # People You May Know Route
  # match 'users/people_you_may_know', :to => 'users#people_you_may_know', :as => :people_you_may_know, :via => [:get]

  # Public Page Routes such as Contact, Privacy, etc
  match 'help/faq', :to => 'public#faq', :via => [:get], :as => :faq
  match 'help/video_faq', :to => 'public#video_faq', :via => [:get], :as => :video_faq
  match 'help/video_guidelines', :to => 'public#video_guidelines', :via => [:get], :as => :video_guidelines 
  match 'help/contact', :to => 'public#contact', :via => [:get], :as => :contact
  match 'help/privacy', :to => 'public#privacy', :via => [:get], :as => :privacy
  match 'help/tos', :to => 'public#tos', :via => [:get], :as => :tos

  # Users Create
  resources :users, :only => [:create]
  
  # Username Availability
  match :username_availability, :to => 'users#username_availability', :via => [:get]
  
  # This needs to go at the bottom of this routes.rb file to catch 
  # all routes that didn't match the routes specified above.
  #
  ## This regex constraint handles these cases: http://rubular.com/r/PiP1nTNph2
  ### alphanumeric with underscores only; can't have consecutive underscores; can't be only an underscore;
  ### can be only a letter; can't start with a number or be only a number; can't contain spaces; can end in an underscore;
  ### can't be only an underscore and numbers (if it starts with an underscore, the next char must be a letter)
  controller :users, :path => '/:username', :as => :user, :constraints => { :username => /_?[a-z]_?(?:[a-z0-9]_?)*/i } do
    resources :badges, :only => [:index]
    resources :channels do
      match :request_access, :to => 'subscriptions#handle_access_request', :via => [:get]
      match :subscribe, :to => 'subscriptions#create', :via => [:post]
      match :unsubscribe, :to => 'subscriptions#destroy', :via => [:delete]
      match :remove_subscriber, :to => 'subscriptions#remove_subscriber', :via => [:delete]
    end
    match :about, :to => 'profile#index', :via => [:get]
    match 'about/update/:id', :to => 'profile#update', :as => :update_about, :via => [:put]
    resources :videos, :except => [:create, :index] do
      resources :badges, :only => [:create, :destroy]
      match 'badges', :to => 'badges#badges_dialog', :as => :badges_dialog, :via => [:get]
      resources :comments, :only => [:create, :destroy]  
      get :embed_code
      match :flag, :to => 'videos#flag', :via => [:post]
      match '/flag/dialog', :to => 'videos#flag_video_dialog', :as => :flag_dialog, :via => [:get]
      match :share_via_email, :to => 'videos#share_via_email'
      resources :tags, :only => [:destroy]
      
      # uploading routes
      post :encoder_callback
      put :successful_upload
      put :upload_error    
    end
    resources :social_networks, :only => [:destroy]
    
    # All matched routes that are nested under User go here
    match '/', :to => 'users#show', :via => [:get]
    match :edit_banner, :to => 'users#edit_banner', :via => [:get]
    match :invite_people, :to => 'invitation_link#create'
    match :invitations, :to => 'invitation_link#index'
    match :latest_activity, :to => 'user_events#show', :via => [:get]
    match 'add_to_channel/dialog', :to => 'videos#add_to_channel_dialog', :as => :add_to_channel_dialog, :via => [:get]
    match 'add_to_channel', :to => 'videos#add_to_channel', :as => :add_to_channel, :via => [:post]
    match 'share/dialog', :to => 'videos#share_dialog', :as => :share_dialog, :via => [:get]
    match 'share', :to => 'videos#share', :as => :create_shared_video, :via => [:post]
    match :edit_featured_videos, :to => 'channels#edit_featured_videos', :via => [:get]
    match :update_featured_videos, :to => 'channels#update_featured_videos', :via => [:put]
    match 'stream', :to => 'users#subscriptions_stream'
    match :account, :to => 'users#edit'
    match 'account/update', :to => 'users#update', :via => [:put]
    match 'account/image', :to => 'users#new_image', :via => [:put]
    match 'account/image_status', :to => 'users#new_image_status', :via => [:get]
    match :update_banner_from_gallery, :to => 'users#update_banner_from_gallery', :via => [:put]
    match :update_background_image, :to => 'users#update_background_image', :via => [:put]
    match 'account/password', :to => 'users#update_password', :via => [:put]
    match 'account/birthday', :to => 'users#update_birthday', :via => [:put]
    match 'account/notifications', :to => 'users#update_notifications', :via => [:put]
    match :subscriptions, :to => 'subscriptions#subscriptions'
    match :subscribers, :to => 'subscriptions#subscribers'
    match :block, :to => 'users#block'
    match :unblock, :to => 'users#unblock'
    match :validate_reset_password, :to => 'users#validate_reset_password', :via => [:get]
    match :reset_password, :to => 'users#reset_password', :via => [:post]
  end

  # Catches all bad routes that weren't matched with the above routes and shows 404 page instead
  match '*a', :to => 'errors#routing'
end

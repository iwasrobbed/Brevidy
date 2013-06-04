if Rails.env.production?
  Airbrake.configure do |config|	
    config.api_key = 'YOUR_API_KEY_HERE' 	
  end
end
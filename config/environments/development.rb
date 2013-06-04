Brevidy::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # ActionMailer configuration
  # config.action_mailer.smtp_settings = {
  #   :address        => "smtp.sendgrid.net",
  #   :port           => "25",
  #   :authentication => :plain,
  #   :user_name      => ENV['SENDGRID_USERNAME'],
  #   :password       => ENV['SENDGRID_PASSWORD'],
  #   :domain         => ENV['SENDGRID_DOMAIN']
  # }
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.default_url_options = { :host => "localhost:3000" }
  # Defaults to:
  # config.action_mailer.sendmail_settings = {
  #   :location => '/usr/sbin/sendmail',
  #   :arguments => '-i -t'
  # }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Set zencoder API key
  Zencoder.api_key = 'YOUR_API_KEY_HERE'
end


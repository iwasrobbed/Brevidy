require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Brevidy
  class Application < Rails::Application
    # To use the following constants prepend the following: Brevidy::Application:: to each.
    # Set Global S3 params based on which environment you are in
    s3_config_filename = "#{Rails.root}/config/amazon/amazon_s3.yml"
    s3_config = YAML.load_file(s3_config_filename)[Rails.env].symbolize_keys
    S3_BUCKET                 = s3_config[:bucket_name]
    S3_ASSET_HOST             = s3_config[:asset_host]
    S3_BASE_URL               = s3_config[:base_url]
    # Set Global S3 constants
    s3_constants_config_filename = "#{Rails.root}/config/amazon/amazon_s3_constants.yml"
    s3_constants_config = YAML.load_file(s3_constants_config_filename).symbolize_keys
    S3_ACCESS_KEY_ID          = s3_constants_config[:access_key_id]
    S3_SECRET_ACCESS_KEY      = s3_constants_config[:secret_access_key]
    S3_REGION                 = s3_constants_config[:region]
    S3_IMAGES_RELATIVE_PATH   = s3_constants_config[:images_relative_path]
    S3_VIDEOS_RELATIVE_PATH   = s3_constants_config[:videos_relative_path]
    # Set Global CloudFront params based on which environment you are in
 	 cf_config_filename = "#{Rails.root}/config/amazon/amazon_cf.yml"
 	 cf_config = YAML.load_file(cf_config_filename)[Rails.env].symbolize_keys
 	 CLOUDFRONT_BASE_URL       = cf_config[:cf_base_url]

    # HTTP Authentication Username/Password for admin users
    HTTP_AUTH_USERNAME          = "username"
    HTTP_AUTH_PASSWORD          = "password"

    # HTTP Authentication Username/Password for zencoder
    HTTP_AUTH_ZEN_USERNAME      = "username"
    HTTP_AUTH_ZEN_PASSWORD      = "password"
    
    # Twitter Auth
    TWITTER_CONSUMER_KEY        = "consumer_key"
    TWITTER_CONSUMER_SECRET     = "consumer_secret"
    
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/lib)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)
    
    # Configure generator to use HAML and to not use fixtures for tests
    # Instead of fixtures, we will use factories through Factory Girl
    config.generators do |g|
      g.template_engine :haml
      g.test_framework :rspec, :fixture => false
    end

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :token]
    
    class << self
      # Removes delayed jobs that had deserialization errors 
      # (meaning the object was deleted before a delayed_job could be performed on it)
      def remove_deserialized_delayed_jobs
        djs = Delayed::Job.where("last_error LIKE '%DeserializationError%'")
        djs.each do |dj|
          dj.destroy
        end
      end
      handle_asynchronously :remove_deserialized_delayed_jobs, :priority => 50
      
      # Initiates the "fs:index" rake task to re-index the models and clean out the delta index.
      def rebuild_sphinx_index
        Rake::Task['fs:index'].invoke
      end
      handle_asynchronously :rebuild_sphinx_index, :priority => 50
    end
  end
end

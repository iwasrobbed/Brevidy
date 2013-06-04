source 'http://rubygems.org'

# there is an issue with rake 0.9.0
gem 'rake', '0.8.7'
# Gems for the development and production environment.
gem 'rails', '3.0.7'
# use the HAML templating engine
gem 'haml'
# generates haml files instead of ERB
gem 'haml-rails'
# use the SASS engine for CSS
gem 'sass'
# paginates large results
gem 'will_paginate'
# date validation
gem 'validates_timeliness'
# used for version control rake task
gem 'heroku'
# used for file upload
gem 'carrierwave'
gem 'fog'
# used for image processing
gem 'mini_magick'
# used for processing jobs asynchronously in the background
gem 'delayed_job_active_record'
# used to encode videos
gem 'zencoder'
# does modern web browser validation for us
gem 'browser'
# used to send a long running rake task into 
# the background as a delayed_job since heroku times them out
gem 'delayed_task'
# used for getting xml data from YouTube and Vimeo links
gem 'httparty'
# used for memcached interaction
gem 'dalli'
# used for facebook/twitter integration
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
# used for accessing the facebook graph api
gem 'koala'
# used for accessing the twitter api
gem 'twitter', '~> 4.0'
# used for creating nested api templates
gem 'rabl'
# used as the JSON parser for the rabl gem
gem 'yajl-ruby'
# this is to get rid of an error with json 1.4.6 
gem 'json', '~> 1.7'

# Gems for the production & staging environments only
group :production, :staging do
  # full text search
  gem 'thinking-sphinx'
  gem 'flying-sphinx'
  # autoscales delayed_job workers via hirefireapp.com
  gem 'hirefireapp'
  # use Factory Girl to create users and video posts
  gem 'factory_girl_rails'
  # use faker to generate pseudo information
  gem 'faker'
  gem 'pg'
end

# Gems for the production environment only
group :production do
  # logs all of our errors (rails/javascript) to airbrake
  gem 'airbrake'
end

# Gems for the local/dev/staging environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'sqlite3'
  # use RSpec for testing instead of Test::Unit
  gem "rspec-rails"
  # use Webrat for RSpec helper functions
  gem 'webrat'
  # gives you the ability to launch a page at any point during test
  gem 'launchy'
  # wipes the db after each run instead of using transactional fixtures
  gem 'database_cleaner'
end
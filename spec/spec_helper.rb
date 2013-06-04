# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'database_cleaner'
require 'faker'
require 'factory_girl'
require File.dirname(__FILE__) + "/custom_matchers"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
# Load up lib tasks
Dir[Rails.root.join("spec/lib/**/*.rb")].each {|f| require f}

# Find factory girl definitions
FactoryGirl.find_definitions

RSpec.configure do |config|
  
  # OmniAuth mocking
  OmniAuth.config.test_mode = true
  # Good mock ups
  OmniAuth.config.add_mock(:twitter,  {  :provider    => "twitter", 
                                         :uid         => "1234", 
                                         :user_info   => { :name      => "BrevidyTW",
                                                           :location  => "Internet" },
                                         :credentials => { :token => "twittertoken",
                                                           :secret => "twittersecret" } 
                                       })
  OmniAuth.config.add_mock(:facebook, {  :provider    => "facebook", 
                                         :uid         => "5678", 
                                         :user_info   => { :name      => "BrevidyFB",
                                                           :email     => "brevidy@brevidy.com" },
                                         :extra       => { :user_hash => { :birthday => "10/1/2010",
                                                                           :location => { :name => "Internet" },
                                                                           :gender => "Male" } },
                                         :credentials => { :token => "facebooktoken" } 
                                       })
  # Mock ups with nil information
  OmniAuth.config.add_mock(:nil_twitter,  {  :provider    => "twitter", 
                                             :uid         => "1234", 
                                             :user_info   => { :name      => nil,
                                                               :location  => nil },
                                             :credentials => { :token => nil,
                                                               :secret => nil } 
                                          })
  OmniAuth.config.add_mock(:nil_facebook, {  :provider    => "facebook", 
                                             :uid         => "5678", 
                                             :user_info   => { :name      => nil,
                                                               :email     => nil },
                                             :extra       => { :user_hash => { :birthday => nil,
                                                                               :location => { :name => nil },
                                                                               :gender => nil } },
                                             :credentials => { :token => nil } 
                                          })
                                                 
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false
  
  # Database cleaner settings
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
  
  ##########################
  ## ERROR CODE CONSTANTS ##
  ##########################
  def ok
    200
  end
  def created
    201
  end
  def accepted
    202
  end
  def unauthorized
    401
  end
  def not_found
    404
  end
  def unprocessable_entity
    422
  end 
  
  ######################
  ## HELPER FUNCTIONS ##
  ######################
  # Tag Helpers
  def test_get_tag_from_tagging(tagging)
    Tag.find_by_id(tagging.tag_id)
  end
  # Comment Helpers
  def test_get_comment_video(comment)
    Video.find_by_id(comment.video_id)
  end
  def test_get_object_owner(object)
    User.find_by_id(object.user_id)
  end
  
  # Signin/Signout Helpers
  def test_sign_in(user)
    controller.sign_in(user)
  end
  def test_sign_out
    controller.sign_out
  end
  def integration_sign_in(user) 
    fill_in :email,	:with => user.email 
    fill_in :password, :with => "password"
    click_button 'Login'
  end
end

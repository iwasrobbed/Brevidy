
######################
### Test Factories ###
######################

FactoryGirl.define do

  # User
  factory :user do |f|
    f.sequence(:name) { |n| "Factory User" }
    f.sequence(:email) { |n| "user#{n}@brevidy.com" }
    f.sequence(:username) { |n| "username_#{n}" }
    f.password "password"
    f.birthday "1993-01-01"      
  end
  
  # Channel
  factory :channel do |f|
    f.association :user
    f.sequence(:title) { |n| "Factory Channel #{n}" }
  end
  
  # Video
  factory :video do |f|
    f.association :user
    f.association :channel
    f.association :video_graph
    f.title { Faker::Lorem.words(num = 10).join(' ').first(50) }
    f.description  { Faker::Lorem.sentences(sentence_count = 5).join(' ').first(250) }
  end
  
  # VideoGraph
  factory :video_graph do |f|
    f.status VideoGraph.get_status_number(:ready)
    f.base_filename "sample_populated"
    f.path "sample_data"
    f.thumbnail_path "sample_data"
    f.encoding_type "enc1"
    f.thumbnail_type "thumb1"
    f.sequence(:user_id) { |n| "#{n}" }
  end
  
  # Comment
  factory :comment do |f|
    f.content "Oh Hai!"
  end
  
  # Tagging
  factory :tagging do |f|
    f.association :video
    f.association :tag
  end
  
  # Tag
  factory :tag do |f|
    f.content "I'm a real tag!"
  end
  
  # Icon
  factory :icon do |f|
    f.name "Test"
    f.css_class "badgeTest"
    f.active "true"
    f.icon_type "badge"
  end
  
  # Badge
  factory :badge do |f|
    f.video_id 1
    f.badge_from 1
    f.badge_type 1
  end
  
  # Users, inherits from the :user test Factory object
  factory :sample_user, :parent => :user do |f|
    f.name { Faker::Name.name.first(25) }
    f.email { Faker::Internet.email }
  end
  
  # Creates a sample user with an attached video
  factory :sample_user_with_existing_content, :parent => :sample_user do |user|
    user.after_create { |a| FactoryGirl.create(:video, :user => a) }
    # add more content here as we create it
  end
  
end
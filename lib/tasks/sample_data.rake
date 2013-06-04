require 'faker'
# pending implementation
# need to rework all of this to bring up-to-date
namespace :db do 
  desc "Filling database with sample data" 
  task :populate => :environment do
    Rake::Task['db:reset'].invoke 
    # seed gets called by default during reset
    make_users 
    make_tags
    make_videos_with_attached_data
    make_subscriptions
    show_login_instructions
  end
  task :super_populate => :environment do
    Rake::Task['db:reset'].invoke 
    # seed gets called by default during reset
    make_users_with_lots_of_videos 
    make_subscriptions
  end
  
  # Used for populating sample data
  task :seed_users => :environment do
    make_users
  end
  task :seed_tags => :environment do
    make_tags
  end
  task :seed_videos_with_attached_data => :environment do
    make_videos_with_attached_data
  end
  task :seed_subscriptions => :environment do
    make_subscriptions
  end
  
  # Seeding tasks for standard database stuff
  task :seed_restricted_usernames => :environment do
    seed_restricted_usernames
  end
  task :seed_badges => :environment do
    seed_badges
  end
  task :seed_flags => :environment do
    seed_flags
  end
  task :seed do
    # all default, production data goes in here and you can define new stuff in a method below
    seed_restricted_usernames
    seed_badges
    seed_flags
    seed_banner_images
  end
  
  def seed_restricted_usernames
    puts "\n**************\n"
    puts "\nLoading the RestrictedUsername table full of restricted names\n"
    puts "\n**************\n\n"
    restricted_usernames = %w(about account ad admin administrator ads ajax android api app apps auth authenticate blog brands
     brevidy brevity business businesses campaign campaigns career careers contact contact_us contest contests create credit credits 
     delete demo design developer developers discover discussions download downloads edit embed engineering event events explore faq 
     featured feedback find group groups help hirefireapp history home inbox info investor investors investor_relations invitation 
     invitations invite ios ipad iphone job jobs join legal live log_in log_out login logout marketing message messages mobile music 
     new notification notifications oembed offer offers official onboarding p partner partners password payment payments people popular 
     preferred premier premium press press_center privacy private public recent recommended remove rss sale sales search secure security 
     session sessions setting settings share sign_in sign_out sign_up signin signout signup soulofvideo spam stream subscribe subscribers 
     subscriptions suggested tag tags team terms theater theaters theatre theatres thesoulofvideo tools tos tour tv update upgrade user 
     users video videos vlog watch welcome wiki)
    restricted_usernames += Rails.application.routes.routes.map(&:path).join("\n").scan(/\s\/(\w+)/).flatten.compact.uniq 
    uniq_restricted_usernames = restricted_usernames.uniq
    
    inclusive_restricted_usernames = %w(admin administrator brevidy brevity)
    
    uniq_restricted_usernames.each do |u|
      RestrictedUsername.create(:username => u, :inclusive => inclusive_restricted_usernames.include?(u))
    end
  end
  
  def seed_badges
    puts "\n**************\n"
    puts "\nLoading the Icon table full of default badges\n"
    puts "\n**************\n\n"
      badges = [{:icon_type => "badge", :name => "Creative", :css_class => "badgeCreative", :active => true},   
        {:icon_type => "badge", :name => "Beautiful", :css_class => "badgeBeautiful", :active => true},
        {:icon_type => "badge", :name => "Clever", :css_class => "badgeClever", :active => true},
        {:icon_type => "badge", :name => "Creepy", :css_class => "badgeCreepy", :active => true},
        {:icon_type => "badge", :name => "Cute", :css_class => "badgeCute", :active => true}, 
        {:icon_type => "badge", :name => "Dislike it", :css_class => "badgeDislikeIt", :active => true}, 
        {:icon_type => "badge", :name => "Epic", :css_class => "badgeEpic", :active => true}, 
        {:icon_type => "badge", :name => "Evil", :css_class => "badgeEvil", :active => true}, 
        {:icon_type => "badge", :name => "Fail", :css_class => "badgeFail", :active => true}, 
        {:icon_type => "badge", :name => "Gifted", :css_class => "badgeGifted", :active => true}, 
        {:icon_type => "badge", :name => "Hilarious", :css_class => "badgeHilarious", :active => true}, 
        {:icon_type => "badge", :name => "Hot", :css_class => "badgeHot", :active => true}, 
        {:icon_type => "badge", :name => "Huh?", :css_class => "badgeHuh", :active => true}, 
        {:icon_type => "badge", :name => "Inspirational", :css_class => "badgeInspirational", :active => true}, 
        {:icon_type => "badge", :name => "Like it", :css_class => "badgeLikeIt", :active => true}, 
        {:icon_type => "badge", :name => "Love it", :css_class => "badgeLoveIt", :active => true}, 
        {:icon_type => "badge", :name => "Naughty", :css_class => "badgeNaughty", :active => true}, 
        {:icon_type => "badge", :name => "Original", :css_class => "badgeOriginal", :active => true}, 
        {:icon_type => "badge", :name => "Sad", :css_class => "badgeSad", :active => true}, 
        {:icon_type => "badge", :name => "Scary", :css_class => "badgeScary", :active => true},
        {:icon_type => "badge", :name => "Trendy", :css_class => "badgeTrendy", :active => true},  
        {:icon_type => "badge", :name => "Wise", :css_class => "badgeWise", :active => true}, 
        {:icon_type => "badge", :name => "Wow...", :css_class => "badgeWow", :active => true}, 
        {:icon_type => "badge", :name => "Yummy", :css_class => "badgeYummy", :active => true}]

      badges.each do |b|
        puts "Loading #{b[:name]} badge..."
        icon = Icon.new(:icon_type => b[:icon_type], :name => b[:name], :css_class => b[:css_class], :active => b[:active])
        icon.save!
      end
  end
  
  def seed_flags
    puts "\n**************\n"
    puts "\nLoading the flags table with default flags\n"
    puts "\n**************\n\n"
      flags = [{:reason => "There is something wrong with this video"},
               {:reason => "This video is inappropriate, offensive, or violates the video guidelines"},
               {:reason => "This video is spam, misleading, or mass-advertising"},
               {:reason => "This video infringes my rights or invades my privacy"}]

    flags.each do |f|
      puts "Creating '#{f[:reason]}' flag..."
      flag = Flag.new(:reason => f[:reason])
      flag.save!
    end
  end
  
  def seed_banner_images
    puts "\n**************\n"
    puts "\nAdded the 30 default banner images\n"
    puts "\n**************\n\n"
    image_path = "images/banners"
    for n in 1..30 do BannerImage.create(:path => image_path, :filename => "banner-#{n}.jpg") end
  end
  
  def make_users
      puts "Creating users..."
      # generate users
      users = []
      100.times { users << FactoryGirl.create(:sample_user_with_existing_content) }

      # add a standard user for us to login with
      users << FactoryGirl.create(:user, :name => 'Test User', :email => 'user@brevidy.com', :password => 'password') 
      
      std_user = User.find_by_email("user@brevidy.com")
      std_user.save!
  end
  
  def make_users_with_lots_of_videos
      puts "Creating 101 users with 500 videos each.  This might take a while..."
      # generate users
      users = []
      100.times { users << FactoryGirl.create(:user) }

      # add a standard user for us to login with
      users << FactoryGirl.create(:user, :name => 'Test User', :email => 'user@brevidy.com', :password => 'password') 
      
      users.each do |u|
        500.times { u.videos.create(:description => "Some description here", 
                                    :thumbnail_path => "thumbs/thumb3.jpg",
                                    :path => "videos/ok.m4v") }
      end
      
      std_user = User.find_by_email("user@brevidy.com")
      std_user.save!
  end

  def make_tags
    puts "Creating tags..."
      tags = ["Costa Rica", "bridges", "puentes", "forests", "trees", "dinosaurs", "smegma", "i'm a polar bear", "weeeeeee", "okay"]
      created_tags = []
      tags.each do |t|
        created_tags << Tag.create(:content => t)
      end
  end

  def make_videos_with_attached_data
    puts "Creating videos with associated data..."
    videos = Video.all
    videos_for_standard_user = videos[1..20]
    videos_for_first_user = videos[21..101]
    videos_for_standard_user.each do |v|
      v.user_id = User.find_by_email("user@brevidy.com").id
      v.save
    end
    videos_for_first_user.each do |v|
      v.user_id = User.first.id
      v.save
    end
    videos.each do |v|
      v.set_status(VideoGraph::READY)
      v.path = "sample_data"
      v.base_filename = "sample_populated"
      v.thumbnail_path = "sample_data"
      v.save
  
      # add some tags to it
      Tag.all.each do |c|
        unless Tagging.where(:video_id => v.id, :tag_id => c.id).first
          # join relationship is unique
          new_tagging = v.taggings.new(:tag_id => c.id)
          new_tagging.save
        end
      end
  
      # give it a couple comments
      comments = ["I wake up in the mornin' and I piss excellence!", "How much wood could a woodchuck chuck if a woodchuck could chuck wood?  http://www.it_would.com/chuck_this?much(LOTS)"]
      comments.each do |c|
        c = v.comments.new(:content => c)
        c.user_id = User.first.id
        c.save
      end
      other_user_comment = "I'm the user that has most of the videos, yay!!!"
      other_user_comment = v.comments.new(:content => other_user_comment)
      other_user_comment.user_id = User.find_by_id(1).id
      other_user_comment.save
    end
  end
  
  def make_subscriptions
    puts "Creating subscriptions..."
    users = User.all
    user = User.find_by_email("user@brevidy.com")
    following = users[1..99]
    followers = users[1..99]
    # pending implementation
    puts "Needs implementation"
    #following.each { |followed| user.follow!(followed) }
    #followers.each { |follower| follower.follow!(user) }
  end

  def show_login_instructions
    # login instructions
    puts "\n**************\n\nGenerated the following pseudo users:\n\n" 
    User.all.each do |u|
      puts "Name: #{u.name}, E-mail: #{u.email}"
    end
    puts "\n**************\n\nThe following accounts are available for login:\n"
    puts "\nRole: General User" 
    puts "\nE-mail: user@brevidy.com"
    puts "\nPassword: password"
    puts "\n**************\n\n"
  end
  
end

# this has to be at the end (outside the namespace)
require 'tasks/delayed_tasks'


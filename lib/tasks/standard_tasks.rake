namespace :brevidy do
  desc "checking secure cloudfront urls for connectivity"
  task :check_cloudfront_urls => :environment do
    include HTTParty
    vids_to_check = Video.joins(:video_graph).where(:video_graphs => {:remote_host => nil})
    urls_to_check = []
    vids_to_check.each {|v| urls_to_check << v.generate_secure_cf_url}
    responses = []
    urls_to_check.each {|u| puts "#{HTTParty.get(u).response} for User #{u.split('/')[5]} and Video #{u.split('/')[6]}"}
    #quick_sample = urls_to_check.sample
    #puts "#{HTTParty.get(quick_sample).response} for User #{quick_sample.split('/')[5]} and Video #{quick_sample.split('/')[6]}"
  end
end

namespace :css do
  VERSION = "1.0.3"
  BREVIDY_CSS_NAME = "i_love_lamp-#{VERSION}.css" 
  BREVIDY_MIN_CSS_NAME = "i_love_lamp-#{VERSION}.min.css" 
  SASS_COMMAND = "sass --load-path lib --style"
  SCSS_DIRECTORY = "assets/stylesheets"
  CSS_TARGET_DIRECTORY = "public/stylesheets"

  desc "build regular version of I Love Lamp"
  task :convert => :environment do
    sh "#{SASS_COMMAND} expanded #{SCSS_DIRECTORY}/i_love_lamp.scss:#{CSS_TARGET_DIRECTORY}/#{BREVIDY_CSS_NAME}"
  end

  desc "build compresed version of I Love Lamp"
  task :compress => :environment do
    sh "#{SASS_COMMAND} compressed #{SCSS_DIRECTORY}/i_love_lamp.scss:#{CSS_TARGET_DIRECTORY}/#{BREVIDY_MIN_CSS_NAME}"
  end

  desc "rebuild regular version of I Love Lamp when modifications are made"
  task :watch => :environment do
    sh "#{SASS_COMMAND} expanded --watch #{SCSS_DIRECTORY}/i_love_lamp.scss:#{CSS_TARGET_DIRECTORY}/#{BREVIDY_CSS_NAME}"
  end
  
end
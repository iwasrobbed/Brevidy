# Deploy and rollback on Heroku in testing, staging and production
task :deploy_testing => ['deploy:set_testing_app', 'deploy:push', 'deploy:restart', 'deploy:tag']
task :deploy_testing_with_migrations => ['deploy:set_testing_app', 'deploy:push', 'deploy:off', 
                                            'deploy:migrate', 'deploy:reindex', 'deploy:restart', 'deploy:on', 'deploy:tag']
task :rollback_testing => ['deploy:set_testing_app', 'deploy:off', 'deploy:push_previous', 
                           'deploy:restart', 'deploy:on']
task :rollback_testing_to_tag => ['deploy:set_testing_app', 'deploy:off', 'deploy:rollback_to_tag', 
                                  'deploy:restart', 'deploy:on']

task :deploy_staging => ['deploy:set_staging_app', 'deploy:push', 'deploy:restart', 'deploy:tag']
task :deploy_staging_with_migrations => ['deploy:set_staging_app', 'deploy:push', 'deploy:off', 
                                            'deploy:migrate', 'deploy:reindex', 'deploy:restart', 'deploy:on', 'deploy:tag']
task :rollback_staging => ['deploy:set_staging_app', 'deploy:off', 'deploy:push_previous', 
                           'deploy:restart', 'deploy:on']
task :rollback_staging_to_tag => ['deploy:set_staging_app', 'deploy:off', 'deploy:rollback_to_tag', 
                                  'deploy:restart', 'deploy:on']
                                                                                  
task :deploy_production => ['deploy:set_production_app', 'deploy:push', 'deploy:restart', 'deploy:tag']
task :deploy_production_with_migrations => ['deploy:set_production_app', 'deploy:push', 'deploy:off', 
                                            'deploy:migrate', 'deploy:reindex', 'deploy:restart', 'deploy:on', 'deploy:tag']
task :rollback_production => ['deploy:set_production_app', 'deploy:off', 'deploy:push_previous', 
                           'deploy:restart', 'deploy:on']
task :rollback_production_to_tag => ['deploy:set_production_app', 'deploy:off', 'deploy:rollback_to_tag', 
                                     'deploy:restart', 'deploy:on']

namespace :deploy do
  PRODUCTION_APP = 'brevidytest'
  STAGING_APP = 'brevidytest'
  TESTING_APP = 'brevidytest'

  task :set_testing_app do
    APP = TESTING_APP
  end
  
  task :set_staging_app do
    APP = STAGING_APP
  end

  task :set_production_app do
  	APP = PRODUCTION_APP
  end

  task :push do
    case APP
    when TESTING_APP
      BRANCH = 'development'
      puts 'Deploying Development Branch to Heroku Testing ...'
    when STAGING_APP
      BRANCH = 'staging'
      puts 'Deploying Staging Branch to Heroku Staging ...'
    when PRODUCTION_APP
      BRANCH = 'master'
      puts 'Deploying Master Branch to Heroku Production ...'  
    end
    
    puts `git push -f git@heroku.com:#{APP}.git #{BRANCH}:master`
  end
  
  task :restart do
    puts 'Restarting app servers ...'
    puts `heroku restart --app #{APP}`
  end
  
  task :tag do
    current_commit_hash = `git rev-parse HEAD`
    release_name = "#{APP}_release-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_#{current_commit_hash.strip}"
    puts "Tagging release as '#{release_name}'"
    puts `git tag -a -m 'Tagged release' #{release_name}`
    puts `git push --tags git@heroku.com:#{APP}.git`
  end
  
  task :reindex do
    puts 'Re-indexing Sphinx ...'
    puts `heroku rake fs:rebuild --app #{APP}`
  end
  
  task :migrate do
    puts 'Running database migrations ...'
    puts `heroku rake db:migrate --app #{APP}`
  end
  
  task :off do
    puts 'Putting the app into maintenance mode ...'
    puts `heroku maintenance:on --app #{APP}`
  end
  
  task :on do
    puts 'Taking the app out of maintenance mode ...'
    puts `heroku maintenance:off --app #{APP}`
  end
  
  task :rollback_to_tag do
    prefix = "#{APP}_release-"
    releases = `git tag`.split("\n").select { |t| t[0..prefix.length-1] == prefix }.sort
    puts "Current tags you can rollback to:"
    puts `git tag`
    puts "Enter the tag name you want to roll back to:"
    previous_release = STDIN.gets.chomp
    current_release = releases.last
    if previous_release
      puts "Rolling back to '#{previous_release}' ..."
  
      puts "Checking out '#{previous_release}' in a new branch on local git repo ..."
      puts `git checkout #{previous_release}`
      puts `git checkout -b #{previous_release}`
  
      puts "Removing tagged version '#{previous_release}' (now transformed in branch) ..."
      puts `git tag -d #{previous_release}`
      puts `git push git@heroku.com:#{APP}.git :refs/tags/#{previous_release}`
  
      puts "Pushing '#{previous_release}' to Heroku master ..."
      puts `git push git@heroku.com:#{APP}.git +#{previous_release}:master --force`
  
      puts "Deleting rollbacked release '#{current_release}' ..."
      puts `git tag -d #{current_release}`
      puts `git push git@heroku.com:#{APP}.git :refs/tags/#{current_release}`
  
      puts "Retagging release '#{previous_release}' in case you need to repeat this process (other rollbacks)..."
      puts `git tag -a #{previous_release} -m 'Tagged release'`
      puts `git push --tags git@heroku.com:#{APP}.git`
  
      puts "Switching back to the master branch ..."
      puts `git checkout master`
      puts 'All done!'
    else
      puts "You did not enter in a tag name - can't roll back!  See valid tag names below"
      puts `git tag`
    end
  end

  task :push_previous do
    prefix = "#{APP}_release-"
    releases = `git tag`.split("\n").select { |t| t[0..prefix.length-1] == prefix }.sort
    current_release = releases.last
    previous_release = releases[-2] if releases.length >= 2
    if previous_release
      puts "Rolling back to '#{previous_release}' ..."
      
      puts "Checking out '#{previous_release}' in a new branch on local git repo ..."
      puts `git checkout #{previous_release}`
      puts `git checkout -b #{previous_release}`
      
      puts "Removing tagged version '#{previous_release}' (now transformed in branch) ..."
      puts `git tag -d #{previous_release}`
      puts `git push git@heroku.com:#{APP}.git :refs/tags/#{previous_release}`
      
      puts "Pushing '#{previous_release}' to Heroku master ..."
      puts `git push git@heroku.com:#{APP}.git +#{previous_release}:master --force`
      
      puts "Deleting rollbacked release '#{current_release}' ..."
      puts `git tag -d #{current_release}`
      puts `git push git@heroku.com:#{APP}.git :refs/tags/#{current_release}`
      
      puts "Retagging release '#{previous_release}' in case you need to repeat this process (other rollbacks)..."
      puts `git tag -a #{previous_release} -m 'Tagged release'`
      puts `git push --tags git@heroku.com:#{APP}.git`
      
      puts "Switching back to the master branch ..."
      puts `git checkout master`
      puts 'All done!'
    else
      puts "You did not enter in a tag name - can't roll back!  See valid tag names below"
      puts releases
    end
  end
end
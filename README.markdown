## Brevidy 
Brevidy was a video social network that I built with Ruby on Rails 3.0.7, HAML, Bootstrap, and jQuery that was released into beta testing February 2012.  Brevidy closed down shortly after due to the high costs of server hosting in addition to all of the add-on services such as video transcoding, email, error exception handling, database storage, etc.  Unfortunately, it's very difficult to get investor interest without knowing a friend of a friend, so I wasn't able to afford the rising costs that accompanied the user growth.

The idea of Brevidy was to create a place that people could upload their own videos or cross-post YouTube/Vimeo videos into public or private channels that other people could subscribe to.  When you subscribe to other people's channels, all videos from those channels show up in an infinitely-scrolling stream and you can easily re-share, comment, or badge a video.  It was a beautiful website, but video is a difficult and expensive medium so unfortunately it didn't work out.

## Sites built off of Brevidy

Have a site you wanna share that is built off of the Brevidy code?  Tweet me [https://twitter.com/iwasrobbed](https://twitter.com/iwasrobbed)

* [Ohdin - Find the best UAV operators and latest aerial footage. Organized by the pilots, builders and the public.](http://ohdin.com/)

## Screenshots
<a style="padding:10px" href="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/3d328b5a642998059a701b946ef44be2-original.png"><img src="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/3d328b5a642998059a701b946ef44be2-original.png" alt="Screenshot" style="width: 200px;"/></a>
<a style="padding:10px" href="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/3af5aef6c273ff705932aa1dbcbdefaa-original.png"><img src="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/3af5aef6c273ff705932aa1dbcbdefaa-original.png" alt="Screenshot" style="width: 200px;"/></a>
<a style="padding:10px" href="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/f34402ae95165f2cb7a7473324c82dd2-original.png"><img src="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/f34402ae95165f2cb7a7473324c82dd2-original.png" alt="Screenshot" style="width: 200px;"/></a>
<a style="padding:10px" href="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/1b6dd24854f07d8aa24c51b626821ebc-original.png"><img src="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/1b6dd24854f07d8aa24c51b626821ebc-original.png" alt="Screenshot" style="width: 200px;"/></a>
<a style="padding:10px" href="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/8d9084367c13629411d5e3574cbfc19c-original.png"><img src="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/8d9084367c13629411d5e3574cbfc19c-original.png" alt="Screenshot" style="width: 200px;"/></a>
<a style="padding:10px" href="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/16f006fbab4135124e634e4bfc29ad71-original.png"><img src="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/16f006fbab4135124e634e4bfc29ad71-original.png" alt="Screenshot" style="width: 200px;"/></a>
<a style="padding:10px" href="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/1d3363cf3242f058b235cedfc0b7ee4b-original.png"><img src="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/1d3363cf3242f058b235cedfc0b7ee4b-original.png" alt="Screenshot" style="width: 200px;"/></a>
<a style="padding:10px" href="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/2f29bec475fd70582c0edfd8ef0eb810-original.png"><img src="https://s3.amazonaws.com/screenshots.angel.co/bc/23502/2f29bec475fd70582c0edfd8ef0eb810-original.png" alt="Screenshot" style="width: 200px;"/></a>

## Open Sourcing
I learned a lot about web programming by creating Brevidy and instead of it sitting and collecting dust, I wanted to open source it for others to learn from and use bits and pieces in their own projects.  If you want to create your own video social network using Brevidy as a starting point, be my guest, but **do not** use the Brevidy name, logo, branding, or badges in your website.  Just make sure you give me (Rob Phillips) credit in the About section and I welcome any and all PayPal donations

<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=8QD95M6JCP73C"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif"/></a>

The source code can be used in personal and commercial products for free as long as you give me attribution.  Please also remember that Brevidy was only possible by using other open source projects, so be sure to give them any credit that is necessary according to their respective licenses.

## Collaboration
I would love to see Brevidy come back to life one day, even if it's under a different name and owner.  I welcome all collaborators on this project so please feel free to fork and issue pull requests to improve upon Brevidy.  Much of it was built while I was teaching myself Ruby / Ruby on Rails so I'm sure there is a lot that could be easily improved upon.  If you show enough interest, I would gladly accept people to start working as full-time collaborators and grant you read-write access to the repo so you can commit directly.

## 3rd Party Services
Brevidy uses the following 3rd party services:

  * Zencoder - Very quickly handles all video transcoding from any number of formats for a fair price.  The founder is a great guy and very helpful
  * Amazon S3 & Cloudfront - Handles all image and video storage in addition to high-speed CDN streaming of videos that are hosted on Brevidy.  Amazon is incredible and cheap
  * SendGrid - Their customer service was pretty terrible, but it was the only option I had at the time for sending all of the emails
  * Flying Sphinx - Great search tool for Thinking Sphinx.  The founder is really quick to help and a nice guy
  * HireFire - Manages hiring and firing worker processes on Heroku.  I'm not sure why Heroku never built this automation into their system from the beginning, but necessity is the mother of all invention (and capitalism) so kudos to the creator 

## Getting Started Locally

  1. [Download and unzip these files](http://brevidyassets.s3.amazonaws.com/Bucket_Setup.zip) into the root directory of your Amazon S3 bucket (you'll need to modify the `crossdomain.xml` and `clientaccesspolicy.xml` files before uploading videos will work)
  2. Clone this repository to a local directory on your computer
  3. Create a new ruby set using something like RVM and run `bundle install` in the local repo directory
  4. Run `rake db:reset` to reset and seed the database with default tables and some necessary data
  5. Run `rails generate delayed_job:active_record` and `rake db:migrate` to add the Delayed Jobs table
  6. Update the access keys, buckets, etc. throughout the app (see below for a list)
  7. Run `rails s` to start the Rails server
  8. Open up a new terminal window and run `rake jobs:work` to start the Delayed Jobs workers

Access keys, buckets, etc. that you'll need to update (some are optional, but you'll at least need to update the Amazon S3 data):

```ruby
app/models/video_graph.rb
config/amazon/amazon_cf.yml
config/amazon/amazon_s3.yml
config/amazon/amazon_s3_constants.yml
config/amazon/*.pem
config/application.rb
config/environments/development.rb
config/environments/production.rb
config/environments/staging.rb
config/environments/test.rb
config/initializers/airbrake.rb
config/initializers/secret_token.rb
config/initializers/omniauth.rb
lib/tasks/deploy.rake
```

Note: Brevidy's search is built on top of Flying Sphinx, which only runs on Heroku.  So if you type something into the search box and yell "Rob, this is broken!!!" then you need to understand that search doesn't work locally, it only works on Heroku after you've set up Flying Sphinx.

## Getting Started on Heroku
  * Complete the tasks in the **Getting Started Locally** section to ensure the app builds and runs locally first
  * Make sure you have a Heroku account and the [Heroku Toolbelt](https://toolbelt.heroku.com/) installed
  * Open up the command line or terminal and type:

```ruby
heroku create <app_name_here> --remote production
```

  * At a minimum you will need to install these Heroku add-ons:

```ruby
memcache:5mb
sendgrid:starter
flying_sphinx:wooden
zencoder:1k
airbrake:developer
```

When Brevidy was running in production, these were some of the add-ons that I had installed (not sure if these add-on names have changed or not)

```ruby
cron:hourly (This doesn't exist anymore, you'll have to convert it over to Heroku's Scheduler)
custom_domains:basic
custom_error_pages
deployhooks:email
flying_sphinx:ceramic
airbrake:developer_plus
logging:expanded
memcache:5mb
newrelic:standard
pgbackups:auto-week
sendgrid:bronze
shared-database:20gb
zencoder:1k
```

  * Push the code up to your Heroku server that you just created using `git push -f git@heroku.com:your_app_name_here.git master:master`
  * After pushing the production codebase, run `heroku run rake db:schema:load --app yourappname`, then `heroku run rake db:seed --app yourappname` to generate a seeded database with the data and tables necessary for running Brevidy
  * You'll need to follow the [documentation for Flying Sphinx](http://flying-sphinx.com/docs) to configure it for search (and you'll get some errors in the Heroku logs if you try to create new users before configuring it)

## SASS & Bootstrap
Brevidy uses the Bootstrap framework for much of it's CSS foundation.  To compile the CSS (which is built using SASS files) into the final versions, run `rake css:compress` and then the output file will be in the `public/stylesheets` directory.  You'll have to update the layouts to use the updated CSS files.  

Note: The source files for all SASS and Javascript are in the `assets` directory

## Templating Engine
Brevidy uses the [HAML](http://haml-lang.com) templating engine for generating all views.  All tabs in your text editor should be set to "Soft Tabs" with **2 spaces**  

To convert HTML (or ERB) to HAML: [http://html2haml.heroku.com](http://html2haml.heroku.com)  
**Note:** You should *always* double check the output code for syntax errors or inefficiencies.

## Testing Configuration
By default, Brevidy uses the [RSpec](http://rspec.info/rails) tool for unit testing with factories for test data.  I was in a rush during the last iteration of Brevidy, so I didn't have time to update any of the controller tests.  I'll leave it as an exercise for you and welcome any pull requests with test corrections.

All spec and factory files should go in the `/spec` folder.

Instead of fixtures, Brevidy uses [Factory Girl](https://github.com/thoughtbot/factory_girl_rails) for creating the following factories of default data and also [Faker](http://faker.rubyforge.org) for generating pseudo data for those objects:

  * Users
  * Video Posts
  * Comments & Video Responses
  * Badges Given/Received
  * Description Tags
  * Subscribers/Subscriptions

**Note:** If you do not currently have a test database setup, when you goto run `rspec spec` or `autotest` to run your test suite, it will return failures stating that it cannot find the object tables in the database.  To fix this, make sure you clone the current database for test by running `rake db:test:clone` and all tests should pass after that.

## Doing Work in the Background
Brevidy uses the [DelayedJob](https://github.com/collectiveidea/delayed_job) library for performing long running (background) tasks or tasks that are not time sensitive such as the following:

  * Deleting comments, video responses, users
  * Creating thumbnails for videos and user images
  * Uploading images to S3 and cleaning up on S3
  * Running certain rake tasks

## Deploy Scripts
I wrote some deploy rake tasks to help out with deploying to multiple environments (testing, staging, production).  Have a look in the `lib/tasks/deploy.rake` file to set them up.

There are two options for each depending on if you need to run migrations on the database or not.

    rake deploy_staging
    rake deploy_staging_with_migrations

and

    rake deploy_production
    rake deploy_production_with_migrations

Here is a breakdown of what each task does:

Command:

    rake deploy_#{staging OR production}

What this does:

  * Sets the environment to know whether we want the staging or production app
  * Calls `git push heroku master` to push the latest code to the targeted environment
  * Restarts the Heroku server (it has been known to hang if you don't)
  * Tags the git push in case you need to rollback a bad push.  Tags are formatted like this: `#{APP}_release-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_#{current_commit_hash}`

Command:

    rake deploy_#{staging OR production}_with_migrations

What this does:

  * Sets the environment to know whether we want the staging or production app
  * Calls `git push heroku master` to push the latest code to the targeted environment
  * Calls `heroku maintenance:on` to put the app into Maintenance Mode (which shows our bloated hamster graphic)
  * Runs the database migrations 
  * Restarts the Heroku server (it has been known to hang if you don't)
  * Calls `heroku maintenance:off` to bring the app out of Maintenance Mode
  * Tags the git push in case you need to rollback a bad push.  Tags are formatted like this: `#{APP}_release-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_#{current_commit_hash}`

## Rolling back a bad push
**Note: Pushes have to be tagged for this to work (which happens automatically if you use the rake tasks above).  If you don't tag it, you are SOL and will have to depend on manually force pushing to a specific commit.**

There are two options for each depending on if you want to rollback to the prior push or to a specific tag.

    rake rollback_staging
    rake rollback_staging_to_tag <tag name goes here>

and

    rake rollback_production
    rake rollback_production_to_tag <tag name goes here>

Here is a breakdown of what each task does:

Command:

    rake rollback_#{staging OR production}

What this does:

  * Sets the environment to know whether we want the staging or production app
  * Calls `heroku maintenance:on` to put the app into Maintenance Mode (which shows our bloated hamster graphic)
  * Checks out the LAST tagged push in a new branch on your local git repo
  * Removes that tag 
  * Force pushes that release to Heroku master
  * Deletes the bad, current release
  * Retags the new push in case you need to repeat the process again.  Tags are formatted like this: `#{APP}_release-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_#{current_commit_hash}`
  * Switches back to the master branch 
  * Restarts the Heroku server (it has been known to hang if you don't)
  * Calls `heroku maintenance:off` to bring the app out of Maintenance Mode

Command:

    rake rollback_#{staging OR production}_to_tag <tag name goes here>

To get a list of available tags:

    git tag

    # will output something like this:
    # Robs-Laptop:rails robphillips$ git tag
    #   gotsoultesting_release-20110525195713_d94abc5dd3c30cc52c6859a374878043ebb4aaae
    #   gotsoultesting_release-20110527012602_d94abc5dd3c30cc52c6859a374878043ebb4aaae
    #   gotsoultesting_release-20110530144933_d94abc5dd3c30cc52c6859a374878043ebb4aaae

What this does:

  * Sets the environment to know whether we want the staging or production app
  * Calls `heroku maintenance:on` to put the app into Maintenance Mode (which shows our bloated hamster graphic)
  * Checks out the SPECIFIED, tagged, prior release in a new branch on your local git repo
  * Removes that tag 
  * Force pushes that release to Heroku master
  * Deletes the bad, current release
  * Retags the new push in case you need to repeat the process again.  Tags are formatted like this: `#{APP}_release-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_#{current_commit_hash}`
  * Switches back to the master branch 
  * Restarts the Heroku server (it has been known to hang if you don't)
  * Calls `heroku maintenance:off` to bring the app out of Maintenance Mode

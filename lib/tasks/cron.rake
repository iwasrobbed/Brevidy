desc "Heroku Hourly & Daily Cron Jobs"
task :cron => :environment do
  # Run times depend on what time the cron add-on was
  # added.  So if it was added at 10:32, then it will 
  # run hourly at 32 past the hour or daily at 10:32
  
  # Run hourly
    # retry videos that had submitting errors
    puts "Retrying videos that had submitting errors..."
    VideoGraph.resubmit_videos_with_submitting_errors

  # Run daily between 4 and 5 AM
  if Time.now.hour == 4
    # set uploading_error status for any videos that have been in the
    # uploading state for more than 12 hours
    puts "Finding stale videos and setting to :uploading_error state..."
    VideoGraph.check_videos_for_stale_uploading_states
    # clean up videos that had fatal or uploading errors
    puts "Removing videos that are in an irreparable state..."
    VideoGraph.remove_irreparable_videos
    puts "Removing delayed jobs that had deserialization errors..."
    Brevidy::Application.remove_deserialized_delayed_jobs
    # re-index Flying Sphinx
    puts "Re-indexing the Flying Sphinx Index..."
    Brevidy::Application.rebuild_sphinx_index
  end
end
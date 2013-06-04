begin
  # find if there are already any delayed jobs for this
  # and remove them if so
  video_pending_encoding_jobs = Delayed::Job.where("handler LIKE '%run_pending_or_failed_video_encodings_without_delay%'")
  unless video_pending_encoding_jobs.count == 1
    video_pending_encoding_jobs.each do |j|
      j.destroy
    end
    # initialize the delayed_job polling function
    # for finding pending videos that need encoding
    VideoGraph.run_pending_or_failed_video_encodings
  end
  
rescue
  puts "Rescued database access error for starting encoding delayed job.  You must be loading up the DB for the first time."
end
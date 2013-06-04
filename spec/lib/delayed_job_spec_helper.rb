module DelayedJobSpecHelper
  def test_complete_all_jobs
    Delayed::Job.all.each do |job|
      job.payload_object.perform
      job.destroy
    end
  end
end
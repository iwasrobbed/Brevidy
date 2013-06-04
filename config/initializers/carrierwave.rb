CarrierWave.configure do |config|
    config.cache_dir = "#{Rails.root}/tmp/uploads"
    config.storage = :fog

    config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => Brevidy::Application::S3_ACCESS_KEY_ID,
      :aws_secret_access_key  => Brevidy::Application::S3_SECRET_ACCESS_KEY,
      :region                 => Brevidy::Application::S3_REGION
    }
    config.fog_directory  = Brevidy::Application::S3_BUCKET
    config.fog_host       = Brevidy::Application::S3_BASE_URL
    config.fog_public     = true
    config.fog_attributes = {'Cache-Control' => 'max-age=315576000'}
end
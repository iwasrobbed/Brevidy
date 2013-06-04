class BannerUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  # Override the directory where uploaded files will be stored.
  def store_dir
    "uploads/images/#{model.id}"
  end
  
  # Generate a banner image
  version :resized do
    process :resize_to_fill => [850, 315]
  end

  # Set the filename for versioned files
  def filename
    # appending .jpg onto the end causes MiniMagick to
    # automatically convert the image to that format
    random_token = Digest::SHA2.hexdigest("#{Time.now.utc}--#{model.id.to_s}").first(15)
    ivar = "@#{mounted_as}_secure_token"	
    token = model.instance_variable_get(ivar)
    token ||= model.instance_variable_set(ivar, random_token)
    "banner_#{model.id}_#{token}.jpg" if original_filename
  end
    
end

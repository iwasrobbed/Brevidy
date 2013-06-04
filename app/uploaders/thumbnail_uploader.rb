class ThumbnailUploader < CarrierWave::Uploader::Base
  # include MiniMagick support for resizing images
  include CarrierWave::MiniMagick
  
  # Override the directory where uploaded files will be stored.
  def store_dir
    "#{model.thumbnail_path}"
  end
  
  process :resize_to_fill => [250, 134]

  # Set the filename
  def filename
    # appending .png onto the end causes MiniMagick to
    # automatically convert the image to that format
    "#{model.thumbnail_type}_#{model.base_filename}_0000.png" if original_filename
  end
    
end

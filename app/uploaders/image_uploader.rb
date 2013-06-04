class ImageUploader < CarrierWave::Uploader::Base
  # include MiniMagick support for resizing images
  include CarrierWave::MiniMagick
  
  # Choose what kind of storage to use for this uploader:
  # (handled in the initializer file)
  # storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  def store_dir
    "uploads/images/#{model.id}"
  end
  
  # Create different versions of your uploaded files:
  version :large_profile do
    # returns a 150x150 image with rounded corners
    process :resize_to_fill => [150, 150]
    # process :rounded_corners => [20]
  end
  version :medium_profile do
    # returns a 50x50 image
    process :resize_to_fill => [50, 50]
  end
  version :small_profile do
    # returns a 35x35 image
    process :resize_to_fill => [35, 35]
  end

  # Set the filename for versioned files
  def filename
    # appending .jpg onto the end causes MiniMagick to
    # automatically convert the image to that format
    random_token = Digest::SHA2.hexdigest("#{Time.now.utc}--#{model.id.to_s}").first(10)
    ivar = "@#{mounted_as}_secure_token"	
    token = model.instance_variable_get(ivar)
    token ||= model.instance_variable_set(ivar, random_token)
    "#{model.id}_#{token}.jpg" if original_filename
  end
  
=begin
# Code for rounding corners of an image
# Only works on PNG files and with RMagick though :\
  def rounded_corners(radius)
    manipulate! do |img|
      mask = ::Magick::Image.new(img.columns, img.rows) {self.background_color = 'black'}
      
      gc = ::Magick::Draw.new
      gc.stroke('white').fill('white')
      gc.roundrectangle(0, 0, img.columns - 1, img.rows - 1, radius, radius)
      gc.draw(mask)

      mask.matte = false
      img.matte = true

      thumb = img.composite(mask, Magick::CenterGravity, Magick::CopyOpacityCompositeOp)
      thumb.alpha(Magick::ActivateAlphaChannel)
      thumb.format = 'png'
      #thumb.display
      puts "has alpha? #{thumb.alpha?} and returned #{thumb.inspect}"
      thumb
    end
  end
=end
    
end

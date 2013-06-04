class BannerImage < ActiveRecord::Base
end


# == Schema Information
#
# Table name: banner_images
#
#  id         :integer         not null, primary key
#  path       :string(255)
#  filename   :string(255)
#  active     :boolean         default(TRUE)
#  created_at :datetime
#  updated_at :datetime
#


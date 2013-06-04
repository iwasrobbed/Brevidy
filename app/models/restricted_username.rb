class RestrictedUsername < ActiveRecord::Base
end

# == Schema Information
#
# Table name: restricted_usernames
#
#  id         :integer         not null, primary key
#  username   :string(255)
#  inclusive  :boolean         default(FALSE)
#  created_at :datetime
#  updated_at :datetime
#


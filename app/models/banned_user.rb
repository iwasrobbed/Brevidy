class BannedUser < ActiveRecord::Base
  validates :email,            :presence => true
  validates :reason,           :presence => true
  validates :detailed_reason,  :presence => true
end




# == Schema Information
#
# Table name: banned_users
#
#  id              :integer         not null, primary key
#  email           :string(255)
#  reason          :text
#  created_at      :datetime
#  updated_at      :datetime
#  detailed_reason :text
#


class Flag < ActiveRecord::Base
  # Defines which attributes can be mass-assigned via a form POST (be careful here)
  attr_accessible :reason
  
  validates :reason, :presence => true
end



# == Schema Information
#
# Table name: flags
#
#  id         :integer         not null, primary key
#  reason     :string(255)
#  created_at :datetime
#  updated_at :datetime
#


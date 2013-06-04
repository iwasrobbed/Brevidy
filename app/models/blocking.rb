class Blocking < ActiveRecord::Base
  # protect all attributes from mass-assignment
  attr_protected :id, :requesting_user, :blocked_user, :created_at, :updated_at
  
  validates :requesting_user,   :presence => true
  validates :blocked_user,      :presence => true
  
  belongs_to :blocked_people, :foreign_key => "blocked_user", :class_name => "User"
end



# == Schema Information
#
# Table name: blockings
#
#  id              :integer         not null, primary key
#  requesting_user :integer
#  blocked_user    :integer
#  created_at      :datetime
#  updated_at      :datetime
#


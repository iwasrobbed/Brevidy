class Icon < ActiveRecord::Base
  # validates these attribute conditions are met
  validates :icon_type, :presence => true
  validates :name,      :presence => true
  validates :active,    :inclusion => { :in => [true, false] }
  
  scope :active, where(:active => true)
  scope :order_by_name, order(:name)
  scope :badges, where(:icon_type => "badge")
  
  has_many :badges, :dependent => :destroy, 
                    :foreign_key => 'badge_type'
  
  # Returns the "type" of icon based on primary key                  
  def badge_type
    self.id
  end
end




# == Schema Information
#
# Table name: icons
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  css_class  :string(255)
#  active     :boolean
#  created_at :datetime
#  updated_at :datetime
#  icon_type  :string(255)
#


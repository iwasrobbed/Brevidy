class Badge < ActiveRecord::Base  
  # Defines which attributes can be mass-assigned via a form POST (be careful here)
  attr_accessible :badge_type
  
  # validates these attribute conditions are met
  validates :video_id,    :presence => { :message => "^There was no video ID passed in" }
  validates :badge_type,    :presence => { :message => "^There was no badge type passed in" }
  validates :badge_from,  :presence => { :message => "^There was no person passed in for who the badge is from" }
  
  # Active Record relationships
  belongs_to :video
  belongs_to :icon

  scope :most_recent, limit(50)
  
  # Returns the proper name for a given badge type
  def name
    Icon.find_by_id(self.badge_type).name
  end
  # Returns the CSS class name for a given badge type
  def css_class
    Icon.find_by_id(self.badge_type).css_class
  end
  def from
    User.find_by_id(self.badge_from)
  end

  class << self
    # returns how many badges and of what type a user has that are viewable by current user
    def badges_count_for_type(badge_type)
      Badge.where(:badge_type => badge_type).count
    end
  end
    
end




# == Schema Information
#
# Table name: badges
#
#  id         :integer         not null, primary key
#  video_id   :integer
#  badge_type :integer
#  badge_from :integer
#  created_at :datetime
#  updated_at :datetime
#


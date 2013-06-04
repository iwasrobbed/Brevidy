class Tag < ActiveRecord::Base
  # Defines which attributes can be mass-assigned via a form POST (be careful here)
  attr_accessible :content
  
  # strip and downcase the content before saving
  before_validation :prepare_tag_content, :on => :create

  # validates these attribute conditions are met
  validates :content,   :presence => { :message => "^Your tag can't be blank" },
                        :length => { :maximum => 250,
                                     :message => "^Tags can only be a maximum of 250 characters long" }
  
  # Active Record relationships
  has_many :videos, :through => :taggings
  has_many :taggings, :dependent => :destroy
  
  private 
    def prepare_tag_content
      self.content = self.content.downcase.strip unless self.content.blank?
    end
end







# == Schema Information
#
# Table name: tags
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  content    :string(255)
#


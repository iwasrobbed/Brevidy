class Tagging < ActiveRecord::Base
  # Defines which attributes can be mass-assigned via a form POST (be careful here)
  attr_accessible :tag_id
  
  before_create :populate_video_owner_id_from_video
  
  # update the Video delta flag for Sphinx index after save/destroy
  after_save :set_video_delta_flag
  before_destroy :set_video_delta_flag

  
  # validations
  validates :tag_id,    :presence => { :message => "^The tagging does not have a tag ID." }
  validates :video_id,  :presence => { :message => "^The tagging does not have a video ID." }
  
  belongs_to :video
  belongs_to :tag
  
  private
    def populate_video_owner_id_from_video
      self.video_owner_id = Video.find_by_id(self.video_id).user_id
    end
    
    def set_video_delta_flag
      # check if blank (mostly to fix failing tests)
      unless video.blank?
        video.delta = true 
        video.save
      end
    end
end





# == Schema Information
#
# Table name: taggings
#
#  id             :integer         not null, primary key
#  video_id       :integer
#  tag_id         :integer
#  created_at     :datetime
#  updated_at     :datetime
#  video_owner_id :integer
#


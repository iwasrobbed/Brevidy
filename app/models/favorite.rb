class Favorite < ActiveRecord::Base
  # Defines which attributes can be mass-assigned via a form POST (be careful here)
  attr_accessible :video_id

  # validates these attribute conditions are met
  validates :user_id,   
    :presence => { :message => "^There was no user ID passed in so we were unable to save this to your favorites" },
    :uniqueness => { :scope => :video_id, 
                     :message => "^You have already favorited that video"}
                     
  validates :video_id,  
    :presence => { :message => "^There was no video ID passed in so we were unable to save this to your favorites" }
  
  validates :video_owner_id,
    :presence => { :message => "^There was no video owner ID passed in so we were unable to save this to your favorites." }
         
  # Active Record Relationships                           
  belongs_to :user
  belongs_to :video
  
end


# == Schema Information
#
# Table name: favorites
#
#  id             :integer         not null, primary key
#  user_id        :integer
#  video_id       :integer
#  created_at     :datetime
#  updated_at     :datetime
#  video_owner_id :integer
#

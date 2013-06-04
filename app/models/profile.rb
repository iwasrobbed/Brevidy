class Profile < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::SanitizeHelper
  
  # Defines which attributes can be mass-assigned via a form POST (be careful here)
  attr_accessible :website, :bio, :interests, :favorite_music, :favorite_movies, :favorite_books, 
                  :favorite_foods, :favorite_people, :things_i_could_live_without, 
                  :one_thing_i_would_change_in_the_world, :quotes_to_live_by
  
  belongs_to :user
  
  # validates these attribute conditions are met
  validates :user_id, 
    :presence => { :message => "No user ID was passed in so a profile couldn't be created." }
  validates :bio, :length => { :maximum => 140, :message => "can only be a maximum of 140 characters long" }
  validates :interests,:favorite_music,:favorite_movies,:favorite_books,:favorite_people,
    :favorite_foods,:things_i_could_live_without,:one_thing_i_would_change_in_the_world,
    :length => { :maximum => 1000, :message => "can only be a maximum of 1000 characters long" }    
  validates :quotes_to_live_by,   
    :length => { :maximum => 3000, :message => "can only be a maximum of 3000 characters long" }   
  validates :website, :format => { :with => /\A#{URI::regexp(%w(http https))}\z/,
                                   :message => "^The website you provided is invalid.  Please make sure it starts with 'http://' or 'https://'" }, 
                      :length => { :maximum => 250, :message => "can only be a maximum of 250 characters long" },
                      :allow_nil => true,
                      :allow_blank => true                    
                                     
  # create a hash of profile attributes
  def profile_hash
    %w{website bio interests favorite_music favorite_movies favorite_books favorite_foods 
       favorite_people things_i_could_live_without one_thing_i_would_change_in_the_world
       quotes_to_live_by}
  end
  def categories_to_hash(type)
    profile_hash.inject({}) do |hash, property|
      if type == 'html'
        hash[property] = simple_format(auto_link(h(self.send(property)), :html => { :target => "_blank" }), {}, :sanitize => false)
      else
        hash[property] = self.send(property)
      end
      hash
    end    
  end
  
end






# == Schema Information
#
# Table name: profiles
#
#  id                                    :integer         not null, primary key
#  user_id                               :integer
#  interests                             :text
#  favorite_music                        :text
#  favorite_movies                       :text
#  favorite_books                        :text
#  favorite_people                       :text
#  things_i_could_live_without           :text
#  one_thing_i_would_change_in_the_world :text
#  quotes_to_live_by                     :text
#  created_at                            :datetime
#  updated_at                            :datetime
#  favorite_foods                        :text
#  bio                                   :string(255)
#  website                               :string(255)
#


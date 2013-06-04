class SocialNetwork < ActiveRecord::Base
  
  belongs_to :user
  
  validates :user_id, :uid, :provider, :presence => { :message => "^We were unable to retrieve your social graph data." }
  validates :provider, :inclusion => { :in => ["facebook", "twitter"] }
  validate :uid_and_provider_are_unique, :on => :create
  
  class << self
    # decodes Base64 URL encoded strings
    def base64_url_decode(str)
     str += '=' * (4 - str.length.modulo(4))
     Base64.decode64(str.tr('-_','+/'))
   end
  end
  
  private
    # custom validations
    def uid_and_provider_are_unique
      errors.add(:uid, "^There is already a Brevidy account associated with these #{provider.capitalize} credentials.") if SocialNetwork.where(:uid => uid, :provider => provider).exists?
    end
    
end






# == Schema Information
#
# Table name: social_networks
#
#  id           :integer         not null, primary key
#  uid          :string(255)
#  provider     :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  token        :string(255)
#  user_id      :integer
#  token_secret :string(255)
#


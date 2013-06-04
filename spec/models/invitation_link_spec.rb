require 'spec_helper'

describe InvitationLink do
end




# == Schema Information
#
# Table name: invitation_links
#
#  id                      :integer         not null, primary key
#  user_id                 :integer
#  email_asking_for_invite :string(255)
#  invitation_limit        :integer
#  token                   :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  has_been_invited        :boolean         default(TRUE)
#  click_count             :integer         default(0)
#


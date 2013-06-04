class InvitationLink < ActiveRecord::Base
  # Defines which attributes can be mass-assigned via a form POST (be careful here)
  attr_accessible :email_asking_for_invite

  # Lifecycle actions
  after_create :set_invitation_defaults
  
  # Constants
    # sets whether we should invite people immediately or not (might help signups)
    WE_SHOULD_INVITE_THEM_IMMEDIATELY = true
  
  # Model relationships
  belongs_to :user
  
  # Validations for beta signups
  before_validation :generate_token, :on => :create
  validate :recipient_has_not_already_been_invited, :on => :create, :if => :email_asking_for_invite
  validates :token, :presence => true

  class << self
    # Increments click counts and returns InvitationLink object if there is one
    def handle_invite_token(token)
      invitation_token ||= token.strip rescue nil
      if invitation_token
        invitation = InvitationLink.where(:token => invitation_token).first
        invitation.increment_click_count! if invitation
      end
      
      return invitation
    end
    
    # Handles inviting new users
    def invite_new_users!(recipient_emails, invite_owner, personal_message)
      invite_errors = []
      blank_email_count = 0

      # strip out anything between quotes
      recipient_emails = self.strip_quotes(recipient_emails)

      # split the emails by looking for a comma
      recipient_emails = recipient_emails.split(',')

      # Process each split entity
      recipient_emails.each do |recipient_email|
        # Strip off leading/trailing whitespace and make everything lower case
        recipient_email = recipient_email.strip.downcase

        # Checks for and ignores a blank email address between commas
        if !recipient_email.blank?
          recipient_email = self.extract_email_address(recipient_email)
          if self.this_is_a_valid_email?(recipient_email)
            if User.where(:email => recipient_email).exists?
              invite_errors << "#{recipient_email} is already a member of Brevidy"
            else
              # check if we are doing a beta signup or if a current user is inviting new people
              if invite_owner.blank?
                # a new person is signing up for beta
                @invitation_link = InvitationLink.new(:email_asking_for_invite => recipient_email)
              
                if !@invitation_link.save
                  invite_errors << @invitation_link.errors.full_messages
                end
              else
                # the current user is inviting someone new with their link
                @invitation_link = invite_owner.invitation_link
                UserMailer.delay(:priority => 40).invitation(@invitation_link, recipient_email, personal_message)
              end
            end
          else
            invite_errors << "#{recipient_email} is an invalid email address"
          end
        else
          # Keep track of all blank email addresses
          blank_email_count += 1
        end
      end

      # This checks for situation where only blank email addresses were detected.
      if blank_email_count == recipient_emails.size
        invite_errors << "You have not specified any email addresses to invite"
      end
      # return true unless there were errors and then return the errors
      return invite_errors.flatten unless invite_errors.empty?
    end
  end
  
  # increments the clicked count for invite analytics tracking
  # to show how many times the invitation link was clicked or navigated to
  def increment_click_count!
    self.increment! :click_count
  end
  
  private
    # Validation checks
    # beta signups
    def recipient_has_not_already_been_invited
      # this will catch if a person wanting beta access already invited themselves
      email = email_asking_for_invite.strip.downcase
      errors.add(:email_asking_for_invite, "^#{email_asking_for_invite} has already been added to the invitation list") if InvitationLink.where(:email_asking_for_invite => email).exists?
    end
    
    class << self
      # Validates an email address
      def this_is_a_valid_email?(email)
        email.match(User::EMAIL_REGEX)
      end

      # Strips anything with double quotes from the email address field
      # i.e. "Rob Phillips" <rob@brevidy.com> would return just <rob@brevidy.com>
      def strip_quotes(emails)
        return emails.gsub(/".*?"/, '')
      end

      # If email address is within <>, extract out address, or return original address if not between <>.
      def extract_email_address(email)
        # Check for <@> pattern and extract
        result = email[/<.+@.+>/]
        if result.nil?
          # If not found, return original email address for further validation
          return email
        else
          # If found return address minus the <> and leading/trailing spaces
          return result.gsub(/[<>]/,'<' => '', '>' => '').strip
        end
      end
    end

    # sets the default invitation limit and boolean depending
    # on if it's a beta signup or not
    def set_invitation_defaults
      if self.email_asking_for_invite
        self.invitation_limit = 1
        self.has_been_invited = false
        self.save
      else
        self.has_been_invited = true
        self.save
      end
    end

    # Generates a random invite token
    def generate_token
      loop do
        new_token = Digest::SHA1.hexdigest([Time.now, rand].join).first(35)
        break self.token = new_token unless InvitationLink.where(:token => new_token).exists?
      end
    end
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


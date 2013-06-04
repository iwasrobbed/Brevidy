class InvitationLinkController < ApplicationController
  before_filter :set_user, :verify_user_owns_page, :set_featured_videos
  
  # GET /:username/invitations
  def index
    @browser_title ||= "Invite People"

    respond_to do |format|
      if User::USERS_CAN_INVITE_MORE_PEOPLE
        format.html # index.html.haml
      else
        # don't show the page unless site-wide invites are enabled
        format.html { redirect_to(current_user) }
      end
    end
  end 

  # POST /:username/invitations
  def create
    recipient_emails = params[:recipient_email]
    if recipient_emails.blank?
      render :json => { :error => "You have not specified any email addresses to invite." }, 
             :status => :unprocessable_entity
    else
      personal_message = params[:personal_message]
      invitation_validation_errors = InvitationLink.invite_new_users!(recipient_emails, current_user, personal_message)
      if invitation_validation_errors.blank?
        render :json => { :message => "Thank you!  We have sent an email inviting each person!" }, 
               :status => :ok
      else
        # return the errors
        render :json => { :error => invitation_validation_errors }, 
               :status => :unprocessable_entity
      end
    end
  end

end

class UserMailer < ActionMailer::Base
  default :from => "Brevidy <noreply@brevidy.com>"
  
  # Notifies the user that they have been permanently banned
  def banned(user_email, reason)
    @user_email = user_email
    @reason = reason
    
    mail( :to => @user_email,
          :subject => "Your Brevidy account has been banned")
  end
  
  # Sends a celebratory email for a new user
  def celebrate_new_user(user)
    @user = user
    @user_count = User.count
    mail( :to => "support@brevidy.com",
          :subject => "Yay!!! A new user signed up!")
  end
  
  # Sends the user instructions on how to confirm their account
  def confirmation_instructions(user)
    @user = user
    @url = user_confirm_url(@user, :token => @user.confirmation_token)
    mail( :to => @user.email,
          :subject => "Please confirm your email address")
  end
  
  # Notifies the user that their account has been deactivated
  def deactivated(user, reason)
    @user = user
    @reason = reason
    
    mail( :to => @user.email,
          :subject => "Your Brevidy account has been deactivated")
  end
  
  # Notifies the user of a fatal error with their video
  def fatal_error_on_video(user)
    @user = user
    
    mail( :to => @user.email,
          :subject => "There was an error processing your video")
  end
  
  # Notifies the user when a video they posted has been featured by Brevidy
  def featured_video(user)
    @user = user
    @url = explore_url
    mail( :to => @user.email,
          :subject => "Yay! Your video was featured!" )
  end
  
  # Notifies support@brevidy.com about a flagged video
  def flagged_video(video_flag, current_user)
    @video_flag = video_flag
    @reason = @video_flag.detailed_reason
    @flag_type_description = Flag.find_by_id(@video_flag.flag_id).reason
    @video = Video.find_by_id(@video_flag.video_id)
    @video_owner = User.find_by_id(@video.user_id)
    @url_to_flagged_by = user_url(current_user) unless current_user.blank?
    @url_to_video = user_video_url(@video_owner, @video)
    @url_to_owner = user_url(@video_owner)
    
    mail( :to => "support@brevidy.com",
          :subject => "FLAGGED: Video #{@video.id} has been flagged for review")
  end
  
  # Sends an invitation email out
  def invitation(invitation, recipient_email, personal_message)
    @personal_message = personal_message
    @sender = User.find_by_id(invitation.user_id)
    @token = invitation.token
    @site_url = root_url
    @url = signup_via_invitation_url(:invitation_token => @token)
    
    if @sender.blank?
      subject = "Invitation to join Brevidy!"
    else
      subject = "#{@sender.name} invited you to join Brevidy!"
    end
    
    mail( :to => recipient_email,
          :subject => subject)
  end
  
  # Notifies the user that someone just subscribed to one of their channels
  def new_subscriber(publisher, subscriber, channel)
    @publisher = publisher
    @subscriber = subscriber
    @channel = channel
    @url = user_url(@subscriber)
    @account_url = user_account_url(@publisher)
    
    mail( :to => @publisher.email,
          :subject => "#{@subscriber.name} subscribed to one of your channels on Brevidy" )
  end
  
  # Notifies the user of a new comment on their video
  def new_comment(comment, person_we_are_emailing, the_comment_is_a_reply)
    @comment = comment
    @person_we_are_emailing = person_we_are_emailing
    @the_comment_is_a_reply = the_comment_is_a_reply
    @video = Video.find_by_id(@comment.video_id)
    @video_owner = User.find_by_id(@video.user_id)
    @commenter = User.find_by_id(@comment.user_id) 
    @url = user_video_url(@video_owner, @video)
    @default_image = "#{Brevidy::Application::S3_BASE_URL}/images/default_user_50px.jpg"
    @account_url = user_account_url(@person_we_are_emailing)
    
    @the_comment_is_a_reply ? (subject = "#{@commenter.name} also commented on #{@video_owner.name}'s video") : (subject = "#{@commenter.name} just commented on your video")
    mail( :to => @person_we_are_emailing.email,
          :subject => subject )
  end
  
  # Notifies the user of a new badge on their video
  def new_badge(badge)
    @badge = badge
    @video = Video.find_by_id(@badge.video_id)
    @video_owner = User.find_by_id(@video.user_id)
    @badge_from = User.find_by_id(@badge.badge_from)
    @icon = Icon.find_by_id(@badge.badge_type)
    @url = user_video_url(@video_owner, @video)
    @default_image = "#{Brevidy::Application::S3_BASE_URL}/images/default_user_50px.jpg"
    @account_url = user_account_url(@video_owner)
    
    mail( :to => @video_owner.email,
          :subject => "New badge on your video")
  end
  
  # Notifies a user that their request to access a channel was approved
  def private_channel_request_approved(requesting_user, channel)
    @requesting_user = requesting_user
    @channel = channel
    @channel_owner = User.find_by_id(@channel.user_id)
    @channel_url = user_channel_url(@channel_owner, @channel)
    @account_url = user_account_url(@requesting_user)
    
    mail( :to => @requesting_user.email,
          :subject => "#{@channel_owner.name} has approved your access request" )
  end
  
  # Notifies the user that their account has been reactivated
  def reactivated(user)
    @user = user
    
    mail( :to => @user.email,
          :subject => "Your Brevidy account has been reactivated")
  end
  
  # Sends out the personal feedback email
  def redesign_feedback(user)
    first_name = user.name.split(' ')[0]
    @user_first_name = first_name.blank? ? user.name : first_name
    @user_url = user_url(user)
    
    mail( :from => "Rob Phillips <rob@brevidy.com>",
          :to => user.email,
          :subject => "A word about the new Brevidy")
  end
  
  # Notifies a user that someone wants access to their private channel
  def request_channel_approval(current_user, channel, channel_request)
    @requesting_user = current_user
    @channel = channel
    @channel_owner = User.find_by_id(@channel.user_id)
    @approve_url = user_channel_request_access_url(@channel_owner, @channel, :approved => true, :token => channel_request.token)
    @ignore_url = user_channel_request_access_url(@channel_owner, @channel, :ignored => true, :token => channel_request.token)
    @account_url = user_account_url(@channel_owner)
    @requesting_user_url = user_url(@requesting_user)
    
    mail( :to => @channel_owner.email,
          :subject => "#{@requesting_user.name} is requesting access to one of your private channels" )
  end
  
  # Sends reset password instructions
  def reset_password_instructions(user)
    @user = user
    @url = user_validate_reset_password_url(@user, :token => @user.reset_token)
    mail( :to => @user.email,
          :subject => "Reset password instructions")
  end
  
  # Newsletters
  def september_2011_newsletter(the_user)
    @user = the_user
    @latest_activity_url = user_latest_activity_url(@user)
    @invitation_link_url = signup_via_invitation_url(:invitation_token => @user.invitation_link.token)
    @whats_happening_url = whats_happening_url()
    @account_url = user_account_url(@user)
    @new_video_url = new_user_video_url(@user)
    @forgotten_password_url = forgotten_password_url()
    
    mail( :to => @user.email,
          :subject => "Latest updates on Brevidy!")
  end
  
  # Shares a video via email
  def share_video(current_user, video, recipient_email, personal_message)
    @user = current_user
    @link_to_video_url = public_video_url(:public_token => video.public_token)
    @personal_message = personal_message
    
    if current_user.blank?
      mail( :to => recipient_email,
            :subject => "Someone has shared a video with you!" )
    else
      mail( :to => recipient_email,
            :subject => "#{current_user.name} has shared a video with you!" )
    end
  end
  
  # Tells the user that their video is done encoding
  def video_is_done_encoding(video_owner, video)
    @user = video_owner
    @link_to_video_url = user_video_url(@user, video)
    @account_url = user_account_url(@user)
    
    mail( :to => @user.email,
          :subject => "Your video is ready to be watched on Brevidy!" )
  end
end

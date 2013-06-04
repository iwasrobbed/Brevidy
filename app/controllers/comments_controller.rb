class CommentsController < ApplicationController
  include ApplicationHelper

  before_filter :set_user
  before_filter :set_video
  before_filter :verify_user_can_access_channel_or_video

  # POST /:username/videos/:video_id/comments
  def create
    comment ||= @video.comments.new(:content => params[:content])
    comment.user_id = current_user.id
    @viewing_via_token_access = (params[:channel_token] == @video.channel.public_token)
  
    video_owner ||= get_object_owner(@video)
    if comment.save
      render :json => { :html => 
                          render_to_string( :partial => 'comments/comment.html',
                                            :locals => { :video => @video,   
                                                         :comment => comment,
                                                         :video_owner => video_owner,
                                                         :hidden_comment => false } ),
                        :video_id => @video.id,
                        :comments_count => @video.comments.count },
             :status => :created
    
      comment.notify_all_users_in_the_conversation(current_user, @video, video_owner)
    else
      render :json => { :error => get_errors_for_class(comment).to_sentence }, 
             :status => :unprocessable_entity
    end
  end

  # DELETE /:username/videos/:video_id/comments/:id
  def destroy
    comment ||= @video.comments.find_by_id(params[:id])
    if comment
      # comment exists, so destroy it if user has permission
      if current_user_owns?(comment) || current_user_owns?(@video)
        if comment.destroy
          render :json => { :comments_count => @video.comments.count },
                 :status => :ok
        else
          render :json => { :error => "There was an error removing your comment." }, 
                 :status => :unprocessable_entity
        end
      else
        render :json => { :error => "You do not own that comment so you cannot delete it." }, 
               :status => :unauthorized
      end
    else
      render :nothing => true, :status => :not_found
    end
  end
   
end

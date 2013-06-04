class TagsController < ApplicationController
  before_filter :set_user, :set_video, :verify_user_owns_page

  # DELETE /:username/videos/:video_id/tags/:id
  def destroy
    tagging ||= @video.taggings.where(:tag_id => params[:id]).first
    if tagging
      # tagging relationship exists, so destroy it 
      if tagging.destroy
        render :json => { :video_id => @video.id,
                          :tags_count => @video.tags.count },
               :status => :ok
      else
        render :json => { :error => "There was an error removing your tag." }, 
               :status => :unprocessable_entity
      end
    else
      render :nothing => true, :status => :not_found
    end
  end

end

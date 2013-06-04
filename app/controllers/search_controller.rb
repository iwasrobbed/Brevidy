require 'riddle'
class SearchController < ApplicationController
  skip_before_filter :site_authenticate
  
  # GET /search/users?q=[term]
  def users
    @browser_title ||= "Find People"
    
    @search_type = "user"
    @term = params[:q]
    searching_for_an_email = !@term.blank? && @term.match(User::EMAIL_REGEX)
    @results_count = 0
    
    # Only perform the search on Heroku
    if Rails.env.production? || Rails.env.staging?
      if @term.blank?
        @users = User.search :order => "@random DESC", :page => params[:page], :per_page => 50
      else
        # Build up search field conditions hash
        @conditions = {}
        @conditions = searching_for_an_email ? {:email => Riddle.escape(@term)} : {:name => Riddle.escape(@term)}
        @users = User.search :conditions => @conditions, :order => :name, :page => params[:page], :per_page => 50
      end
      @results_count = @users.total_entries
    else
      @users = []
    end
    
    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end  
  end
  
  # GET /search/videos?q=[term]  or GET /search/videos?tag=[tag]
  def videos
    @browser_title ||= "Search Public Videos"
    
    @search_type = "video"
    searching_for_a_tag = params[:q].blank?
    @term = searching_for_a_tag ? params[:tag] : params[:q]
    @results_count = 0
    
    # Only perform the search on Heroku
    if Rails.env.production? || Rails.env.staging?
      if @term.blank?
        # use the default extended mode matching to return random results
        @results = Video.search :conditions => {:status => VideoGraph.get_status_number(:ready), :channel_is_private => 'f'},
                                :order => "@random DESC",
                                :page => params[:page], 
                                :per_page => 10
      else
        if searching_for_a_tag
          # only match video tags using the default extended mode matching
          @results = Video.search :conditions => {:tags => Riddle.escape(@term), :status => VideoGraph.get_status_number(:ready), :channel_is_private => 'f'},
                                  :page => params[:page], 
                                  :per_page => 10,
                                  :order => 'created_at DESC'
        else
          # use the default extended mode matching to search the video meta
          @results = Video.search Riddle.escape(@term), :conditions => {:status => VideoGraph.get_status_number(:ready), :channel_is_private => 'f'},
                                  :page => params[:page], 
                                  :per_page => 10,
                                  :order => 'created_at DESC'
        end
      end
      @results_count = @results.total_entries
    else
      @results = []
    end
    
    respond_to do |format|
      params[:page].to_i > 1 ? format.js : format.html
    end  
  end 
   
end
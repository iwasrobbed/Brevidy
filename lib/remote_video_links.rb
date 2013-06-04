module RemoteVideoLinks
  # parses links
  require 'uri'
  # parses the HTML
  require 'nokogiri'
  # grabs data from remote URL
  include HTTParty

  class << self
    # Takes an input remote video URL from the user 
    # and returns the video_id, thumbnail, title, and description for it
    #
    # URLs must be of the form:
    # http://www.youtube.com/watch?v=Ez-F9ORFdkA
    # http://www.vimeo.com/16339841
    #
    def get_video_information_from_link(remote_link)
      video_id = nil
      link_host = nil
      video_title = nil
      video_description = nil
      video_thumbnail = nil
      
      begin
        # Defines what the base video URL should look like
        # i.e. either youtube.com or vimeo.com
        new_uri ||= URI.parse(remote_link)
        # remove the www. portion of the host since some people
        # might paste a link with or without it
        link_host = new_uri.host.gsub('www.', '')

        # Retrieves the video's ID
        video_id = video_id(new_uri, link_host)

        # Gets the data for the video from the host
        video_data = get_video_data(link_host, video_id)
        video_title = video_data[0]
        video_description = video_data[1]
        video_thumbnail = video_data[2]
     
        return [video_id, link_host, video_title, video_description, video_thumbnail]
      
      rescue Exception => e
        #puts "error was #{e}"
        # rescues if the user inserts a bad URL that doesn't have the proper data
        # or other errors such as nil strings if a certain HTML element doesn't
        # exist and gives a nil string... essentially this is a catch all if 
        # something screws up and we couldn't get good data from the link
        
        # return all nils which will throw an error higher up
        return [nil, nil, nil, nil, nil]
      end
    end

    # Returns an HTML5 capable embed link   
    def embed_html5_video_link(link_host, remote_video_id, page_type, video_id)
      
      case page_type
        when "embed"
          # embed page video player
          player_width = "100%"
          player_height = "100%"
          autoplay = 0
        when "individual"
          # public page video player
          player_width = Video::PLAYER_WIDTH
          player_height = Video::PLAYER_HEIGHT
          autoplay = 0
        when "regular"
          # internal page video player
          player_width = Video::PLAYER_WIDTH
          player_height = Video::PLAYER_HEIGHT
          autoplay = 1
      end
      
      case link_host
        when "youtube.com", "youtu.be"
          allowfullscreen = "allowfullscreen"
          extra_params = "autohide=1&amp;fs=1&amp;rel=0&amp;showinfo=0&amp;autoplay=#{autoplay}&amp;color=2882ba"
        when "vimeo.com"
          allowfullscreen = ""
          extra_params = "show_title=0&amp;show_byline=0&amp;show_portrait=0&amp;color=2882ba&amp;api=1&amp;player_id=#{video_id}&amp;autoplay=#{autoplay}"
        when "dailymotion.com"
          allowfullscreen = ""
          extra_params = "highlight=2882ba&amp;related=0&amp;autoPlay=#{autoplay}"
      end
      
      embed_code = "<iframe id='universal_player_#{video_id}' src='#{url(link_host, remote_video_id, true)}?wmode=transparent&amp;#{extra_params}' width='#{player_width}' height='#{player_height}' frameborder='0' scrolling='no' #{allowfullscreen}></iframe>"
      embed_code
    end

    # Returns a standard embed code for either YouTube or Vimeo videos
    def embed_remote_video_link(link_host, remote_video_id, video_id)
      embed_code = nil

      case link_host
        when "youtube.com", "youtu.be"
          # used for iframe code
          # allowfullscreen = "allowfullscreen"
          embed_code = "<object width='#{Video::PLAYER_WIDTH}' height='#{Video::PLAYER_HEIGHT}'><param name='movie' value='#{url(link_host, remote_video_id)}?autoplay=1&amp;autohide=1&amp;fs=1&amp;rel=0&amp;showinfo=0&amp;enablejsapi=1'></param><param name='allowFullScreen' value='true'></param><param name='allowscriptaccess' value='always'></param><embed id='brevidy_player_#{video_id}' src='#{url(link_host, remote_video_id)}?autoplay=1&amp;autohide=1&amp;fs=1&amp;rel=0&amp;showinfo=0&amp;enablejsapi=1' wmode='transparent' type='application/x-shockwave-flash' width='#{Video::PLAYER_WIDTH}' height='#{Video::PLAYER_HEIGHT}' allowscriptaccess='always' allowfullscreen='true'></embed></object>"
        when "vimeo.com"
          # used for iframe code
          # allowfullscreen = ""
          embed_code = "<object width='#{Video::PLAYER_WIDTH}' height='#{Video::PLAYER_HEIGHT}'><param name='allowfullscreen' value='true' /><param name='allowscriptaccess' value='always' /><param name='wmode' value='transparent' /><param name='movie' value='http://vimeo.com/moogaloop.swf?clip_id=#{remote_video_id}&amp;server=vimeo.com&amp;show_title=0&amp;show_byline=0&amp;show_portrait=0&amp;color=2882ba&amp;fullscreen=1&amp;autoplay=1&amp;loop=0&amp;api=1' /><embed wmode='transparent' id='brevidy_player_#{video_id}' src='http://vimeo.com/moogaloop.swf?clip_id=#{remote_video_id}&amp;server=vimeo.com&amp;show_title=0&amp;show_byline=0&amp;show_portrait=0&amp;color=2882ba&amp;fullscreen=1&amp;autoplay=1&amp;loop=0&amp;api=1' type='application/x-shockwave-flash' allowfullscreen='true' allowscriptaccess='always' width='#{Video::PLAYER_WIDTH}' height='#{Video::PLAYER_HEIGHT}'></embed></object>"
      end
         
      # The iframe code does not set wmode correctly for the YouTube player in Google Chrome
      # It appears to be a bug in Chrome since the embed code works just fine and other browsers work fine 
      #embed_code = "<iframe src='#{url(link_host, remote_video_id)}?wmode=transparent' width='#{Video::PLAYER_WIDTH}' height='#{Video::PLAYER_HEIGHT}' frameborder='0' #{allowfullscreen}></iframe>"
      
      embed_code
    end

    # Private Methods
    private    
      # Defines what the video player iframe URL will look like
      def url(link_host, remote_video_id, iframe = false)
        url = nil
        case link_host
          when "youtube.com", "youtu.be"
            if iframe
              url = "http://www.youtube.com/embed/#{remote_video_id}"
            else
              url = "http://www.youtube.com/v/#{remote_video_id}"
            end
          when "vimeo.com"
            url = "http://player.vimeo.com/video/#{remote_video_id}"
          when "dailymotion.com"
            url = "http://www.dailymotion.com/embed/video/#{remote_video_id}"
        end

        url
      end
  
      # Retrieves the JSON data from the hosts which 
      # contains meta data about the video
      def get_video_data(link_host, video_id)
        title = nil
        description = nil
        thumbnail_path = nil
        case link_host
          when "youtube.com", "youtu.be"
            html_url = "http://www.youtube.com/watch?v=#{video_id}"
          when "vimeo.com"
            html_url = "http://www.vimeo.com/#{video_id}"
          when "dailymotion.com"
            html_url = "http://www.dailymotion.com/video/#{video_id}"
        end
        
        # use HTTParty to get the remote doc since using "open(url_here)"
        # returns a 404 not found only when you set the encoding... weird.
        html_to_parse = HTTParty.get(html_url)
        # explicitly set the encoding as UTF-8 or else it will 
        # have intermittent errors with the thumbnail path
        html_doc = Nokogiri::HTML(html_to_parse, nil, 'UTF-8')
        # get the video data by using the Facebook OpenGraph protocol
        # this works for unlisted YouTube videos as well :) since their API
        # doesn't give any data for unlisted videos :(
        unless html_doc.blank?
          # mandatory fields (have to have these or we error out)
          site_name = html_doc.css("meta[property='og:site_name']").first['content']
          regular_thumbnail_path = html_doc.css("meta[property='og:image']").first['content']
          title = html_doc.css("meta[property='og:title']").first['content'].first(75) rescue nil
          
          # optional field (don't error out if this is blank)
          description_contents = html_doc.css("meta[property='og:description']")
          description = description_contents.first['content'].first(1000) unless description_contents.blank?
          
          if site_name.downcase == 'youtube'
            # this is the hq thumbnail for youtube videos
            thumbnail_path = regular_thumbnail_path.gsub('/default', '/hqdefault')
          else
            # this is the normal thumbnail for other sites
            thumbnail_path = regular_thumbnail_path
          end
          
          #puts "Site Name: #{site_name}\nTitle: #{title}\nDescription: #{description}\nThumbnail: #{regular_thumbnail_path}"
        end

        return [title, description, thumbnail_path]
      end  

      # Returns the video_id number when given a full uri
      def video_id(new_uri, link_host)
        video_id = nil
        case link_host
          when "youtube.com"
            # finds where v= and gets the next 11 characters after that
            video_id = new_uri.query.split("v=")[1].slice(0, 11)
          
          when "youtu.be"
            # only returns the first 11 chars without any parameters attached
            video_id = new_uri.path.delete('/').first(11)
            
          when "vimeo.com"
            # only returns the path without any parameters attached
            video_id = new_uri.path.delete('/')
            
          # Removing support since their video ads are extremely annoying
          #when "dailymotion.com"
            # get the ID from uri
            #video_id = new_uri.path.split("video/")[1].split("_")[0]
        end

        video_id
      end
  end
end
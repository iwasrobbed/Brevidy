require 'digest'
module SwfUploadsHelper

  # Creates an instance of an S3 file uploader
  def s3_swf_uploader(media_type)
    @media_type = media_type
    # Set specific options based on media type we are uploading
    case media_type
      when 'banner', 'image'
        @temporary_filename = filename_for_image_upload
        @success_response_path = user_account_image_path(current_user)
        @image_status_path = user_account_image_status_path(current_user, :media_type => media_type)
        @s3_storage_folder = "#{Brevidy::Application::S3_IMAGES_RELATIVE_PATH}/#{current_user.id}"
        @acl = 'public-read'
        @content_type = 'image/jpg'
        @filter_title = 'Images'
        @filter_extensions = 'jpg,jpeg,gif,png'
        @max_filesize = (media_type == 'banner') ? 5.megabytes : 2.megabytes
      when 'video'
        @base_filename = @new_video_graph_object.base_filename
        @temporary_filename = "orig_#{@base_filename}_#{current_user.id}"
        @success_response_path = user_video_successful_upload_path(current_user, @video)
        @video_upload_error_path = user_video_upload_error_path(current_user, @video)
        @s3_storage_folder = "#{Brevidy::Application::S3_VIDEOS_RELATIVE_PATH}/#{current_user.id}"
        @acl = 'private'
        @content_type = 'video/'
        @filter_title = 'Videos'
        @swf_filter_extensions = '*.3gp;*.3gpp;*.mov;*.avi;*.mp4;*.m4v;*.mpg;*.mpeg;*.rm;*.ram;*.ra;*.flv;*.f4v;*.ogm;*.asf;*.wma;*.ivf;*.wmv;*.ogv;*.3gp;*.swf;*.vob;*.divx;*.mts;*.m2ts;'
        @max_filesize = 750.megabytes
    end

    # Set generic defaults
    @s3_base_url = Brevidy::Application::S3_BASE_URL
    @s3_file_key = "#{@s3_storage_folder}/#{@temporary_filename}"
    @expiration_date = 10.hours.from_now.utc.iso8601

    # Generate a policy based on the above
    @policy = swf_generated_policy
    
    # Generate a signature based on the policy
    @signature = swf_generated_signature(@policy)
    
    # Return the javascript given all of the above
    return swfupload_uploader_javascript
  end
  
  private
    # Returns the proper S3 bucket based on the Rails environment
    def swf_bucket
      return Brevidy::Application::S3_BUCKET
    end
  
    # Returns the proper S3 access key based on the Rails environment
    def swf_access_key
      return Brevidy::Application::S3_ACCESS_KEY_ID
    end
  
    # Returns the proper S3 secret access key based on the Rails environment
    def swf_secret_access_key
      return Brevidy::Application::S3_SECRET_ACCESS_KEY
    end
  
    # Returns a generated S3 policy which places restrictions and sets configs
    # for all uploads
    def swf_generated_policy
      return policy = Base64.encode64("{'expiration': '#{@expiration_date}',
                                        'conditions': [
                                          {'bucket': '#{swf_bucket}'},
                                          {'acl': '#{@acl}'},
                                          {'success_action_status': '201'},
                                          ['content-length-range', 0, #{@max_filesize}],
                                          ['starts-with', '$key', '#{@s3_file_key}'],
                                          ['starts-with', '$Content-Type', ''],
                                          ['starts-with', '$Filename', '']
                                        ]
                                      }").gsub(/\n|\r/, '')
    end
  
    # Returns a generated S3 signature based on the secret key and policy
    def swf_generated_signature(policy)
      return signature = Base64.encode64(
                           OpenSSL::HMAC.digest(
                             OpenSSL::Digest::Digest.new('sha1'),
                               swf_secret_access_key, policy)).gsub("\n","")
    end
  
    # Returns a string of javascript for instantiating a SWFUpload uploader object
    def swfupload_uploader_javascript(options = {})
      uploader_js = ""
      uploader_js << javascript_include_tag("uploader/swfupload.and.speed.min")
      uploader_js << javascript_tag("
        $(function() { 
          var new_video = #{@media_type == 'video'};
          var percent_uploaded = 0;
          
          var swf_uploader = new SWFUpload({
          	// SWF Settings
          	flash_url: '/javascripts/uploader/swfupload.swf',
          	prevent_swf_caching: false,
	
	          // Button Settings
          	button_action: SWFUpload.BUTTON_ACTION.SELECT_FILE,
          	button_image_url: '#{cache_buster_path("/javascripts/uploader/select_#{@media_type}_v1.png")}',
          	button_placeholder_id: 'select-#{@media_type}',
          	button_width: 103,
          	button_height: 28,
          	button_window_mode: 'transparent',
          	button_cursor: SWFUpload.CURSOR.HAND,
          	
          	// S3 settings
          	upload_url: '#{@s3_base_url.gsub('https://', 'http://')}',
          	file_post_name: 'file',
          	post_params: {
                'key': '#{@s3_file_key}',
                'Filename': '${filename}',
          			'acl': '#{@acl}',
          			'Content-Type': '#{@content_type}',
          			'success_action_status': '201',
          			'AWSAccessKeyId': '#{swf_access_key}',		
          			'policy': '#{@policy}',
          			'signature': '#{@signature}'
               },

          	// File settings
          	file_size_limit: '#{@max_filesize / 1048576} MB',
          	file_types: '#{@swf_filter_extensions}',			
          	file_types_description: '#{@filter_title}',
          	file_upload_limit: 1,
          	file_queue_limit: 1,

          	// Event handler settings
          	http_success : [201],
          	file_dialog_complete_handler: fileDialogComplete,
          	file_queue_error_handler: fileQueueError,
          	upload_start_handler: uploadStart,
          	upload_progress_handler: uploadProgress,
          	upload_error_handler: uploadError,
          	upload_success_handler: uploadSuccess,

          	// Debug settings
          	debug: #{Rails.env.development?}
          });
          
          function fileDialogComplete() { swf_uploader.startUpload(); }
          
          function uploadStart(file) {
            // Move the uploader browse button off screen
            $('.uploader-area').css({'position':'relative','top':'-9999999px','height':'0'});   
            swf_uploader.setButtonDisabled(true);
            
            $('#progress-bar span').show();
            $('#progress-bar').show('fast', function () { 
              $('#new-video-form').slideDown('fast');
            });  
            
            // warn user if they are still uploading to not leave the page
            window.onbeforeunload = function() {
              return 'You are currently uploading a file.  Are you sure you want to leave this page and cancel the upload?';
            };
          }
          
          function uploadSuccess(file, serverData) {
            $('#progress-bar .progress').css('width', '100%');
            $('#progress-bar span').text('Processing...');
            
            if (new_video) {
              var ajax_data = { };
              $('#new-video-form').submit();
            } else {
              var ajax_data = { 'media_type':'#{@media_type}',
        				                'filename':'#{@temporary_filename}' };
            }
            
            $.ajax({
      				data: ajax_data,
      				type: 'PUT',
      				url: '#{@success_response_path}',
      				success: function(json) {
      				  // Update progress bar
                $('#progress-bar span').text(json.success_message);
      				  
      				  // Start polling for image uploads
      				  if (new_video) { 
      				    $('.success-message.video-saved p').html('Video information saved. You can edit it by <a href=\"'+ json.edit_video_path +'\">clicking here</a>');
      				  } else {
      				    // Start polling for image uploads
      				    simple_poll_request(); 
      				  }
      				},
      				error: function(response) {
      				  // show failure on progress bar
                $('#progress-bar .progress').addClass('error').css('width', '100%');
                $('#progress-bar span').text('Upload Failed :(');

                brevidy.dialog('Error', 'There was an error uploading your file.  Please e-mail us at support@brevidy.com if this continues to happen.', 'error');
      				}
      			});

            // clear out the user warning
            window.onbeforeunload = null;
          }
          
          var progressSpeed = 0;
          function uploadProgress(file, bytesLoaded, bytesTotal) {    
          	if (bytesTotal) {
          		percent_uploaded = (bytesLoaded / bytesTotal) * 100;
          		$('#progress-bar .progress').css('width', percent_uploaded + '%');
          		// Convert to bytes per second and show time left (currentSpeed is bits per second)
          		var speed = SWFUpload.speed.formatBytes(Math.round(file.currentSpeed) * 0.125) + '/s (' + SWFUpload.speed.formatTime(file.timeRemaining) + ' left)';
          		if (progressSpeed == 5 || percent_uploaded > 95) { $('#progress-bar span').text('Uploading... ' + speed); progressSpeed = 1;}
          		progressSpeed++;
          	}
          }

          function fileQueueError(file, errorCode, message)  {
          	switch (errorCode) {
          	case SWFUpload.QUEUE_ERROR.QUEUE_LIMIT_EXCEEDED:
          	  var error_message = 'You can only upload one file at a time.';
          	  break;
          	case SWFUpload.QUEUE_ERROR.FILE_EXCEEDS_SIZE_LIMIT:
          	  var error_message = 'The file you chose was too large (it cannot be larger than ' + #{@max_filesize / 1048576} + ' MB).  Please resize the file or choose a different one to upload.';
          	  break;
          	case SWFUpload.QUEUE_ERROR.ZERO_BYTE_FILE:
          		var error_message = 'The file you selected is empty. Please select another file.';
          	  break;
          	case SWFUpload.QUEUE_ERROR.INVALID_FILETYPE:
          		var error_message = 'The file you choose is not an allowed file type.';
          	  break;
          	default:
          		var error_message = 'An error occurred in the upload. Please email us at support@brevidy.com if this continues to happen.';
          	  break;
          	}
          	brevidy.dialog('Error', error_message, 'error');
          	return;
          }
          
          function uploadError(file, errorCode, message) {
            if (errorCode == SWFUpload.UPLOAD_ERROR.FILE_CANCELLED) { return; }
          	switch (errorCode) {
          	case SWFUpload.UPLOAD_ERROR.HTTP_ERROR:
          		var error_message = message;
          		break;
          	case SWFUpload.UPLOAD_ERROR.UPLOAD_FAILED:
          		var error_message = 'Upload failed';
          		break;
          	case SWFUpload.UPLOAD_ERROR.IO_ERROR:
          		var error_message = 'IO error (check internet connection)';
          		break;
          	case SWFUpload.UPLOAD_ERROR.SECURITY_ERROR:
          		var error_message = 'Security error';
          		break;
          	case SWFUpload.UPLOAD_ERROR.UPLOAD_LIMIT_EXCEEDED:
          		var error_message = 'Upload limit exceeded';
          		break;
          	case SWFUpload.UPLOAD_ERROR.FILE_VALIDATION_FAILED:
          		var error_message = 'Failed validation so upload was skipped';
          		break;
          	case SWFUpload.UPLOAD_ERROR.UPLOAD_STOPPED:
          		var error_message = 'Upload was stopped';
          		break;
          	default:
          		msg = 'Unknown Error (' + errorCode + ')';
          		break;
          	}
          	// Show the user an error box
          	brevidy.dialog('Error', 'There was an error during the upload: ' + error_message, 'error');
          	
          	// Show failure on progress bar
            $('#progress-bar .progress').addClass('error').css('width', '100%');
            $('#progress-bar span').text('Upload Failed :(');
            
            // Send off error to the server
            if (new_video) {
              $.ajax({
                data: { 'error_message':error_message,
                        'file_size':SWFUpload.speed.formatBytes(file.size),
                        'percent_uploaded':Math.round(percent_uploaded),
                        'average_speed':SWFUpload.speed.formatBytes(file.averageSpeed),
                        'moving_average':SWFUpload.speed.formatBytes(file.movingAverageSpeed) },
                type: 'PUT',
                url: '#{@video_upload_error_path}'
              });
            }
                
            // hide the meta area
            $('#new-video-form').slideUp('fast');
                
            // clear out the user warning
            window.onbeforeunload = null;
          }
      });")
    end
 
    # Generates a random string for a temporary image upload (prior to processing the image)
    def filename_for_image_upload
      random_token = Digest::SHA2.hexdigest("#{Time.now.utc}--#{current_user.id.to_s}").first(15)
      "temp_upload_#{random_token}"
    end

end
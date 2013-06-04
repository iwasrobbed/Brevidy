require 'digest'
module UploadsHelper

  # Creates an instance of an S3 file uploader
  def s3_uploader(media_type)
    # Set specific options based on media type we are uploading
    case media_type
      when 'banner', 'image'
        temporary_filename = filename_for_image_upload
        success_response_path = user_account_image_path(current_user)
        image_status_path = user_account_image_status_path(current_user, :media_type => media_type)
        s3_storage_folder = "#{Brevidy::Application::S3_IMAGES_RELATIVE_PATH}/#{current_user.id}"
        acl = 'public-read'
        content_type = 'image/jpg'
        filter_title = 'Images'
        filter_extensions = 'jpg,jpeg,gif,png'
        max_filesize = (media_type == 'banner') ? 5.megabytes : 2.megabytes
      when 'video'
        base_filename = @new_video_graph_object.base_filename
        temporary_filename = "orig_#{base_filename}_#{current_user.id}"
        success_response_path = user_video_successful_upload_path(current_user, @video)
        video_upload_error_path = user_video_upload_error_path(current_user, @video)
        s3_storage_folder = "#{Brevidy::Application::S3_VIDEOS_RELATIVE_PATH}/#{current_user.id}"
        acl = 'private'
        content_type = 'video/'
        filter_title = 'Videos'
        filter_extensions = '3gp,3gpp,mov,avi,mp4,m4v,mpg,mpeg,rm,ram,ra,flv,f4v,ogm,asf,wma,ivf,wmv,ogv,3gp,swf,vob,divx,mts,m2ts'
        max_filesize = 750.megabytes
    end

    # Set generic defaults
    s3_base_url = Brevidy::Application::S3_BASE_URL
    s3_file_key = "#{s3_storage_folder}/#{temporary_filename}"
    expiration_date = 10.hours.from_now.utc.iso8601

    # Generate a policy based on the above
    policy = generated_policy(expiration_date, bucket, acl, max_filesize, s3_file_key)
    
    # Generate a signature based on the policy
    signature = generated_signature(policy)
    
    # Return the javascript given all of the above
    return uploader_javascript(:media_type => media_type, :max_filesize => max_filesize, :acl => acl,
                               :s3_file_key => s3_file_key, :policy => policy, :signature => signature, 
                               :s3_base_url => s3_base_url, :content_type => content_type,
                               :filter_title => filter_title, :filter_extensions => filter_extensions,
                               :temporary_filename => temporary_filename, :base_filename => base_filename, 
                               :success_response_path => success_response_path, :image_status_path => image_status_path,
                               :video_upload_error_path => video_upload_error_path)
  end
  
  private
    # Returns the proper S3 bucket based on the Rails environment
    def bucket
      return Brevidy::Application::S3_BUCKET
    end
  
    # Returns the proper S3 access key based on the Rails environment
    def access_key
      return Brevidy::Application::S3_ACCESS_KEY_ID
    end
  
    # Returns the proper S3 secret access key based on the Rails environment
    def secret_access_key
      return Brevidy::Application::S3_SECRET_ACCESS_KEY
    end
  
    # Returns a generated S3 policy which places restrictions and sets configs
    # for all uploads
    def generated_policy(expiration_date, bucket, acl, max_filesize, s3_file_key)
      return policy = Base64.encode64("{'expiration': '#{expiration_date}',
                                        'conditions': [
                                          {'bucket': '#{bucket}'},
                                          {'acl': '#{acl}'},
                                          {'success_action_status': '201'},
                                          ['content-length-range', 0, #{max_filesize}],
                                          ['starts-with', '$key', '#{s3_file_key}'],
                                          ['starts-with', '$Content-Type', ''],
                                          ['starts-with', '$name', ''],
                                          ['starts-with', '$Filename', '']
                                        ]
                                      }").gsub(/\n|\r/, '')
    end
  
    # Returns a generated S3 signature based on the secret key and policy
    def generated_signature(policy)
      return signature = Base64.encode64(
                           OpenSSL::HMAC.digest(
                             OpenSSL::Digest::Digest.new('sha1'),
                               secret_access_key, policy)).gsub("\n","")
    end
  
    # Returns a string of javascript for instantiating an uploader
    def uploader_javascript(options = {})
      uploader_js = ""
      uploader_js << javascript_include_tag("plupload/plupload.full") 
      uploader_js << javascript_tag("
        $(function() { 
          var plupload_max_file_size = '#{options[:max_filesize] / 1048576} MB';
          var new_video = #{options[:media_type] == 'video'};
          var video_id = 0;
          var uploader_dom_id;
          
          var uploader = new plupload.Uploader({
              runtimes : 'flash',
              browse_button : 'select-#{options[:media_type]}',
              max_file_size : plupload_max_file_size,
              url : '#{options[:s3_base_url].gsub('https://', 'http://')}',
              flash_swf_url: '/javascripts/plupload/plupload.flash.swf',
              filters : [ {title : '#{options[:filter_title]}', extensions : '#{options[:filter_extensions]}'} ],
              init : {
                // Called as soon as a file has been added and prior to upload
                FilesAdded: function(up, files) {
                  uploader_dom_id = up.id + '_' + up.runtime + '_container';
                  
                  // Start the uploader
                  uploader.start();
                  
                  // hide the add files button and show progress bar
                  $('#select-#{options[:media_type]}').fadeOut('fast', function() {
                    $(this).remove();
                  });
                  $('#progress-bar span').show();
                  $('#progress-bar').show('fast', function () { 
                    $('#new-video-form').slideDown('fast');
                  });
                  
                  plupload.each(files, function(file) {
                    if (up.files.length > 1) { up.removeFile(file); }
                  });
      
                  // warn user if they are still uploading to not leave the page
                  window.onbeforeunload = function() {
                    return 'You are currently uploading a file.  Are you sure you want to leave this page and cancel the upload?';
                  };

                },
                FileUploaded: function(up, file, info) {
                  $('#progress-bar .progress').css('width', '100%');
                  
                  if (new_video) {
                    var ajax_data = { };
                    $('#new-video-form').submit();
                  } else {
                    var ajax_data = { 'media_type':'#{options[:media_type]}',
              				                'filename':'#{options[:temporary_filename]}' };
                  }
                  
                  $.ajax({
            				data: ajax_data,
            				type: 'PUT',
            				url: '#{options[:success_response_path]}',
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
      
                },
                UploadProgress: function(up, file) {
                  // Move the uploader browse button off screen
                  $('#' + uploader_dom_id).css('top', '-9999999px');
      
                  // Binds progress to progress bar
                  if(file.percent < 100){
                    $('#progress-bar .progress').css('width', file.percent+'%');
                    $('#progress-bar span').text('Uploading... '+ file.percent +'%');
                  } else {
                    $('#progress-bar .progress').css('width', '100%');
                    $('#progress-bar span').text('Processing... please wait');
                  }                          
                },
                Error: function(up, error) {      
                  var error_message;
      
                  // shows error object
                  if (error.message.indexOf('File size') !== -1) {
                    brevidy.dialog('Error', 'The file you chose was too large (it cannot be larger than ' + plupload_max_file_size + ').  Please resize the file or choose a different one to upload.', 'error');
                  } else {
                    // show failure on progress bar
                    $('#progress-bar .progress').addClass('error').css('width', '100%');
                    $('#progress-bar span').text('Upload Failed :(');
        
                    error_message = error.message;
                    brevidy.dialog('Error', 'There was an error uploading your file: ' + error_message + ' Please e-mail us at support@brevidy.com if this continues to happen.', 'error');
                  
                    if (new_video) {
                      $.ajax({
                        data: { 'error_message':error_message },
                        type: 'PUT',
                        url: '#{options[:video_upload_error_path]}'
                      });
                    }
                    
                  }
                
                  // hide the meta area
                  $('#new-video-form').slideUp('fast');
                      
                  // clear out the user warning
                  window.onbeforeunload = null;
      
                }
              },
              multi_selection: false,
              multipart: true,
              multipart_params: {
                'key': '#{options[:s3_file_key]}',
                'Filename': '${filename}',
          			'acl': '#{options[:acl]}',
          			'Content-Type': '#{options[:content_type]}',
          			'success_action_status': '201',
          			'AWSAccessKeyId' : '#{access_key}',		
          			'policy': '#{options[:policy]}',
          			'signature': '#{options[:signature]}'
               },
              file_data_name: 'file'
          });

          // instantiates the uploader
          uploader.init();


          // A recursive polling function for image processing status
          function simple_poll_request() {
            $.ajax({
      				type: 'GET',
      				url: '#{options[:image_status_path]}',
      				success: function (json) {
      				  if (json.job_status == 'processing') {
      				    // wait 1 second and try again
    				      setTimeout(function() { simple_poll_request(); }, 1000);
    				    } else if (json.job_status == 'success') {
                  // page will redirect
                } else if (json.job_status == 'error') {
                  $('#progress-bar .progress').addClass('error');
                  $('#progress-bar span').text('Processing Error :(');
                  brevidy.dialog('Error', 'There was an error processing your photo.  Please try a different image or e-mail us at support@brevidy.com if this continues to happen.', 'error');
                }
      				}
    				});
  				};

      });")
    end
  
    # Generates a random string for a temporary image upload (prior to processing the image)
    def filename_for_image_upload
      random_token = Digest::SHA2.hexdigest("#{Time.now.utc}--#{current_user.id.to_s}").first(15)
      "temp_upload_#{random_token}"
    end

end
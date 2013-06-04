# encoding: utf-8
begin
  require 'fog'
rescue LoadError
  raise "You don't have the 'fog' gem installed."
end

module Brevidy
  module Fog

    ##
    # Remove things from Amazon S3 using the "fog" gem
    ##

    class S3

      class File
        def initialize
        end        

        ##
        # Remove the file from Amazon S3
        # 
        # Path is structure as "uploads/images/" with no leading / 
        # 
        # Filename is just "filename.ext"
        ##
        def delete(s3_path, filename)
          path_including_filename = s3_path + filename
          #puts "About to delete a file with the key #{path_including_filename}"
          connection.delete_object(Brevidy::Application::S3_BUCKET, path_including_filename)
          #puts "File should no longer exist."
        end
        
        private
          ##
          # Establish a connection to Amazon S3 via Fog
          ##
          def connection
            @connection ||= ::Fog::Storage.new(
              :aws_access_key_id      => Brevidy::Application::S3_ACCESS_KEY_ID,
              :aws_secret_access_key  => Brevidy::Application::S3_SECRET_ACCESS_KEY,
              :provider               => 'AWS',
              :region                 => Brevidy::Application::S3_REGION
            )
          end
      end # File
    end # S3
  end # Fog
end # Brevidy

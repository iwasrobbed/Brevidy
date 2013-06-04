require 'custom_error_message'

ActiveModel::Errors.send(:include, CustomErrorMessage)

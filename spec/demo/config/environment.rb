# Load the rails application
require File.expand_path('../application', __FILE__)

ActiveRecord::Base.logger=Logger.new($stdout) if CONFIG[:force_debug] or Rails.env!="production" && CONFIG[:log_db_to_stdout]!=false

# Initialize the rails application
Demo::Application.initialize!

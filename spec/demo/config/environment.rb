# Load the Rails application.
require File.expand_path('../application', __FILE__)

ActiveRecord::Base.logger=Logger.new($stdout) if CONFIG[:log_db_to_stdout]==true

# Initialize the Rails application.
Demo::Application.initialize!

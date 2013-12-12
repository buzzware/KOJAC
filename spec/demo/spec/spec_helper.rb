# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
#require 'capybara/rspec'
require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

#Capybara.run_server = true #Whether start server when testing
#Capybara.server_port = 8200
#Capybara.default_selector = :css #:xpath #default selector , you can change to :css
#Capybara.default_wait_time = 5 #When we testing AJAX, we can set a default wait time
#Capybara.ignore_hidden_elements = false #Ignore hidden elements when testing, make helpful when you hide or show elements using javascript
#Capybara.javascript_driver = :selenium #default driver when you using @javascript tag

#require 'capybara/poltergeist'
#Capybara.javascript_driver = :poltergeist
#Capybara.register_driver :poltergeist do |app|
#	options = {
#		:js_errors => true,
#		:timeout => 120,
#		:debug => true,
#		:phantomjs_options => ['--load-images=no', '--disk-cache=false'],
#		:inspector => true,
#  }
#  Capybara::Poltergeist::Driver.new(app, options)
#end

#Post-install message from capybara:
#IMPORTANT! Some of the defaults have changed in Capybara 2.1. If you're experiencing failures,
#please revert to the old behaviour by setting:
#
#    Capybara.configure do |config|
#      config.match = :one
#      config.exact_options = true
#      config.ignore_hidden_elements = true
#      config.visible_text_only = true
#    end
#
#If you're migrating from Capybara 1.x, try:
#
#    Capybara.configure do |config|
#      config.match = :prefer_exact
#      config.ignore_hidden_elements = false
#    end
#
#Details here: http://www.elabs.se/blog/60-introducing-capybara-2-1
#



RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true # false # should be false when using Database Cleaner https://www.relishapp.com/rspec/rspec-rails/docs/transactions

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  #config.order = "random"

  # see http://devblog.avdi.org/2012/08/31/configuring-database_cleaner-with-rails-rspec-capybara-and-selenium/
  #config.before(:suite) do      # once only, before set of specs run
  #  DatabaseCleaner.clean_with(:truncation)
  #end
  #
  #config.before :each do
  #  #if Capybara.current_driver == :rack_test
  #    DatabaseCleaner.strategy = :transaction
  #  #else
  #  #  DatabaseCleaner.strategy = :truncation
  #  #end
  #  DatabaseCleaner.start
  #  ActionMailer::Base.deliveries.clear
  #end
  #
  #config.after(:each) do
  #  DatabaseCleaner.clean
  #end

  #config.before(:all) do
  #  DeferredGarbageCollection.start
  #end
  #
  #config.after(:all) do
  #  DeferredGarbageCollection.reconsider
  #end

  #config.include ShowMeTheCookies#, :type => :feature
  #
  ##config.include ProductsHelper
  #config.include ActionView::Helpers::TextHelper
  #
  #config.include(EmailSpec::Helpers)
  #config.include(EmailSpec::Matchers)

	#config.treat_symbols_as_metadata_keys_with_true_values = true
	#config.filter_run_excluding :requires_elasticsearch unless CONFIG[:elasticsearch_available]
end

# Capybara operations normally happen on another thread and connection, and so transactional database cleaning won't work.
# This hack makes all operations share a common connection, and so transactional database cleaning works even for capybara tests
# Also see https://gist.github.com/josevalim/470808 and http://stackoverflow.com/questions/8774227/why-not-use-shared-activerecord-connections-for-rspec-selenium
#class ActiveRecord::Base
#  mattr_accessor :shared_connection
#  @@shared_connection = nil
#
#  def self.connection
#    @@shared_connection || retrieve_connection
#  end
#end
#ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
#
#require 'spec_utils'

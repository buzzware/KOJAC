#Dir.chdir(File.dirname(__FILE__)) { Dir['kojac/*'] }.each {|f| require f }
#require 'kojac/app_serialize'
require 'kojac/version'
require 'kojac/concentric'
require 'kojac/kojac_rails'
require 'kojac/controller'

module Kojac
  module Rails
    class Engine < ::Rails::Engine
    end
  end
end

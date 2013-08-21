Dir.chdir(File.dirname(__FILE__)) { Dir['kojac/*'] }.each {|f| require f }

module Kojac
  module Rails
    class Engine < ::Rails::Engine
    end
  end
end

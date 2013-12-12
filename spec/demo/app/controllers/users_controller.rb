class UsersController < ApplicationController

	include Kojac::ControllerOpMethods

	attr_accessor :current_user

end

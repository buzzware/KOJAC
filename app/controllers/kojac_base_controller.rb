require File.expand_path(File.dirname(__FILE__) + '/kojac_front_methods.rb')

class KojacBaseController < ActionController::Base

	include KojacFrontMethods
	include Kojac::ControllerOpMethods

	respond_to :json

	public

	def receive
		jsono,status = process_input(params[:kojac])
		render json: jsono, status: status
	end

end

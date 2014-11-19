require File.expand_path(File.dirname(__FILE__) + '/kojac_front_methods.rb')

class KojacBaseController < ApplicationController

	include KojacFrontMethods
	respond_to :json
	protect_from_forgery :only => []

	protected

	def kojac_current_user
		current_user
	end

	public

	def receive
		jsono,status = process_input(params[:kojac])
		render json: jsono, status: status
	end

end

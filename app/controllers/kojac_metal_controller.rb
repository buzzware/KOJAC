require 'json'

class KojacMetalController < ActionController::Metal

	include KojacFrontMethods

	protected

	def current_user
		@current_user ||= env['warden'].user #User.find_by(id: session[:user])
	end

	public

  def index
	  input = JSON.parse(request.body.read)
	  jsono,status = process_input(input['kojac'])
    self.response_body = jsono.to_json
	  self.status = status
  end
end

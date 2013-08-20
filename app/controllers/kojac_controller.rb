class KojacController < ApplicationController

	respond_to :json
	protect_from_forgery :only => []

	protected

	def controller_for_key(aKey)
		resource = aKey.split('__').first
		controller_name = resource.camelize+'Controller'
		if controller = controller_name.constantize
			result = controller.new
			result.current_user = self.current_user
			result
		else
			nil
		end
	end

	def process_ops(aInput)
		result = { }
		if ops = aInput[:ops]
			result[:ops] = []
			ops.each do |op|
				method = "#{op[:verb].to_s.downcase}_op".to_sym
				ctrlr = self.controller_for_key(op[:key])
				if ctrlr.respond_to? method
					ctrlr.params = {op: op}
					output = ctrlr.send method
					result[:ops] << output
				else
					raise "Unsupported verb #{op[:verb]}"
				end
			end
		end
		result
	end

	public

	def receive
		input = nil
		output = nil
		status = :ok

    begin
      input = params[:kojac]
      output = process_ops(input)
			status = :ok
    rescue => e
			raise e unless Rails.env.production?
			Rails.logger.debug e.message
			Rails.logger.debug e.backtrace.join("\n")
	    output = {
		    results: nil,
	      errors: [{
		      message: e.message,
	        backtrace: e.backtrace
	      }]
	    }
			status = :unprocessable_entity
    end
    #output = ActiveModel::Serializer.new(output,current_user).to_json
    #sz = output.active_model_serializer.new(output)
    #jsons = sz.to_json(:scope => current_user, :root => false)
    jsons = app_serialize(output,current_user)
    render json: jsons, status: status
	end

end

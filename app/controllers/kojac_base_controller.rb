class KojacBaseController < ApplicationController

	respond_to :json
	protect_from_forgery :only => []

	protected

	def kojac_current_user
		current_user
	end

	def controller_for_key(aKey)
		resource = aKey.split('__').first
		controller_name = resource.camelize+'Controller'
		if controller = controller_name.constantize
			result = controller.new
			result.current_user = self.kojac_current_user
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
      send(:before_process,[input]) if respond_to? :before_process
      output = process_ops(input)
    rescue => e
			#raise e unless Rails.env.production?
			Rails.logger.debug e.message
			Rails.logger.debug e.backtrace.join("\n") unless Rails.env.production?
			handle_exception(e) if respond_to? :handle_exception
	    output = {
		    error: {
			    format: 'KojacError',
			    kind: 'Exception',
		      errors: [{
			      message: e.message
		      }]
		    }
	    }
			output[:error][:errors][0][:backtrace] = e.backtrace unless Rails.env.production?
	    output
    end
		send(:after_process,[input,output]) if respond_to? :after_process
		status = output[:error] ? :unprocessable_entity : :ok
    #output = ActiveModel::Serializer.new(output,current_user).to_json
    #sz = output.active_model_serializer.new(output)
    #jsons = sz.to_json(:scope => current_user, :root => false)
    jsono = KojacUtils.to_jsono(output,scope: kojac_current_user)
    render json: jsono, status: status
	end

end

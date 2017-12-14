module KojacFrontMethods

	protected

	def unauthorized!(aMessage=nil)
		raise ::Pundit::NotAuthorizedError, aMessage||"You are not authorized to perform this action"
	end

	def do_op(op)
		output = nil
		method = "#{op[:verb].to_s.downcase}_op".to_sym
		resource = op[:key].split('__').first
		
		if controller_class = (resource.camelize+'Controller::KojacController').safe_constantize
			ctrlr = controller_class.new
			raise "Unsupported verb #{op[:verb]} on #{class_name}" unless ctrlr.respond_to? method
			ctrlr.kojac_setup(current_user,op) if ctrlr.respond_to? :kojac_setup
			output = ctrlr.send method
		elsif (controller_class = (resource.camelize+'Controller').safe_constantize) and ctrlr = controller_class.new and ctrlr.respond_to?(method) # use rails controller
		# 	result = controller_class.new
		#	raise "Unsupported verb #{op[:verb]} on #{class_name}" unless ctrlr.respond_to? method
			ctrlr.current_user = self.current_user
			ctrlr.params = {op: op}
			output = ctrlr.send method
		# else
		# 	raise "Controller class #{class_name} not defined" unless
		else
			raise "Controller not found for #{resource} resource. Please define #{resource.camelize+'Controller::KojacController'}"
		end
		output
	end
	
	def process_ops(aInput)
		result = {}
		if ops = aInput[:ops]
			result[:ops] = []
			ops.each_with_index do |op,i|
				output = do_op(op)
				if output[:error]
					result[:error] = output[:error]
					result[:error_index] = i
					result.delete :ops
					break
				else
					result[:ops] << output
				end
			end
		end
		result
	end


	def process_input(aInputJson)
		output = nil
		status = :ok

		begin
			send(:before_process, [aInputJson]) if respond_to? :before_process
			output = process_ops(aInputJson)
		rescue => e
			#raise e unless Rails.env.production?
			Rails.logger.debug e.message
			Rails.logger.debug e.backtrace.join("\n") unless Rails.env.production?
			handle_exception(e) if respond_to? :handle_exception

			status_code = 422
			if e.is_a? ::Pundit::NotAuthorizedError
				status_code = 403
			elsif e.is_a? ::StandardExceptions::Exception
				status_code = e.status
			else
				if output.is_a? Hash
					error = output[:error] && output['error']
					status_code = 422
				else
					status_code = 500
				end
			end
			status = ::Rack::Utils::HTTP_STATUS_CODES[status_code || 500].downcase.gsub(/\s|-/, '_').to_sym
			output = {
				error: {
					format: 'KojacError',
					kind: 'Exception',
					errors: [{
										 message: e.message,
										 status: status.to_s,
										 status_code: status_code
									 }]
				}
			}
			output[:error][:errors][0][:backtrace] = e.backtrace unless Rails.env.production?
			output
		end
		send(:after_process, [aInputJson, output]) if respond_to? :after_process
		jsono = KojacUtils.to_jsono(output, scope: current_user)
		[jsono,status]
	end

end

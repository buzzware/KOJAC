module Kojac
	class KojacController
		include ::Kojac::ControllerOpMethods

	  attr_accessor :op, :options, :verb, :key, :value, :params, :current_user
	end
end

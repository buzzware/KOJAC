# http://matthewrobertson.org/blog/2013/08/06/active-record-serializers-from-scratch/

if Rails::VERSION::STRING.split('.').first.to_i < 4
	require 'active_record/serializer_override'
end

def app_serialize(aObject,aScope)
	result = case aObject.class
		when Fixnum then aObject.to_s
		when Bignum then aObject.to_s
		when Array
			sz_class = ActiveModel::ArraySerializer
			sz_class.new(aObject).to_json(:scope => aScope, :root => false)
		when String then aObject
		when FalseClass then 'false'
		when TrueClass then 'true'
		when Symbol then aObject.to_s
		#when Hash
			#sz_class = ActiveModel::Serializer
			#sz_class.new(aObject).to_json(:scope => aScope, :root => false)
		else
			sz_class = aObject.respond_to?(:active_model_serializer) && aObject.send(:active_model_serializer)
			sz_class = DefaultKojacSerializer if !sz_class && aObject.is_a?(ActiveModel)
			if sz_class
				sz_class.new(aObject).to_json(:scope => aScope, :root => false)
			else
				aObject.to_json
			end
	end
	result
end

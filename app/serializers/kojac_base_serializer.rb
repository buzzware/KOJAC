require 'active_model/serializer'

class KojacBaseSerializer < ActiveModel::Serializer

	self.root = false

	def initialize(object, options={})
		super(object,options)
	end

	SERIALIZABLE_TYPES = [NilClass,FalseClass,TrueClass,Fixnum,Bignum,String,Symbol,Hash,Array]

	def attributes
		attrs = nil
		source = if policy = Pundit::policy(scope,object)
			attrs = policy.permitted_attributes(:read).map(&:to_s)
			object.attributes
		elsif object.respond_to? :attributes
			object.attributes
		elsif object.is_a? Hash
			object
		end
		result = {}
		source.each do |k,v|
			k_s = k.to_s
			next if attrs && !attrs.include?(k_s)
			if SERIALIZABLE_TYPES.include? v.class
				result[k_s] = v
			else
				result[k_s] = KojacUtils.to_jsono(v,scope: scope)
			end
		end
		result
	end
end

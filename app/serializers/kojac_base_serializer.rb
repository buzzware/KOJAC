class KojacBaseSerializer < ActiveModel::Serializer

	self.root = false

	def initialize(object, options={})
		super(object,options)
	end

	def attributes
		if policy = Kojac::policy(scope,object,nil)
			attrs = policy.permitted_attributes(:read)
			object.attributes.filter_include(attrs)
		else
			object.attributes
		end
	end
end

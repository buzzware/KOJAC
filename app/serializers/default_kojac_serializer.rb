class DefaultKojacSerializer < ActiveModel::Serializer

	def initialize(object, options={})
		super(object,options)
	end

	def attributes
		object.attributes
	end
end

#ActiveSupport.on_load(:active_model_serializers) do
#  # Disable for all serializers (except ArraySerializer)
#  #ActiveModel::Serializer.root = false
#
#  # Disable for ArraySerializer
#  #ActiveModel::ArraySerializer.root = false
#end

#[Object, Array, FalseClass, Float, Hash, Integer, NilClass, String, TrueClass].each do |klass|
#	klass.class_eval do
#		def to_json(opts = {})
#			MultiJson::use(:oj)
#			MultiJson::dump(self, opts)
#		end
#	end
#end

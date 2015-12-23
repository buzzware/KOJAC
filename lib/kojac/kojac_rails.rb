require 'pundit'

Kernel.class_eval do
  def key_join(aResource,aId=nil,aAssoc=nil)
    result = aResource
    if aId
			result += "__#{aId}"
			result += ".#{aAssoc}" if aAssoc
    end
		result
  end
end

class String
	def is_i?
		!!(self =~ /^[-+]?[0-9]+$/)
  end

	def split_kojac_key
		r,ia = self.split('__')
		id,a = ia.split('.') if ia
		id = id.to_i if id && id.is_i?
		[r,id,a]
	end

	# eg deals__5 => deals
	def resource
		self.split('__')[0]
	end

	# eg. deals__5.options => deals__5
	def base_key
		self.split('.')[0]
	end

	def key_assoc
		self.split('.')[1]
	end
end

module KojacUtils
	module_function

	def model_class_for_key(aKey)
		resource = aKey.split_kojac_key[0]
		resource.singularize.camelize.constantize rescue nil
	end

	def model_for_key(aKey)
		klass = KojacUtils.model_class_for_key(aKey)
		resource,id,assoc = aKey.split_kojac_key
		klass.find(id) rescue nil
	end

	def upgrade_hashes_to_params(aValue)
		if aValue.is_a? Hash
			aValue = ActionController::Parameters.new(aValue) unless aValue.is_a?(ActionController::Parameters)
		elsif aValue.is_a? Array
			aValue = aValue.map {|v| upgrade_hashes_to_params(v)}
		end
		aValue
	end

	def timestamp
		Time.now.to_ms
	end

	def serializer_for(aObject)
		return ::KojacBaseSerializer if aObject.is_a?(Hash)
		return ::ActiveModel::ArraySerializer if aObject.respond_to?(:to_ary)
		return ActiveModel::DefaultSerializer if KojacBaseSerializer::SERIALIZABLE_TYPES.include?(aObject.class)
		return aObject.send(:active_model_serializer) if aObject.respond_to?(:active_model_serializer)
		return aObject.class.send(:active_model_serializer) if aObject.class.respond_to?(:active_model_serializer)
		if sz_class = ActiveModel::Serializer.serializer_for(aObject)
			sz_class
		else
			aObject.respond_to?(:attributes) ? ::KojacBaseSerializer : ActiveModel::DefaultSerializer
		end
	end

	def to_jsono(aObject,aOptions=nil)
		aOptions ||= {}
		if aObject.is_a?(Hash) or aObject.respond_to? :attributes
			serializer_for(aObject).new(aObject,aOptions).serializable_hash
		elsif aObject.respond_to?(:to_ary) && aObject.first  # Array
			item_sz = serializer_for(aObject.first)
		  ActiveModel::ArraySerializer.new(aObject,aOptions.merge(each_serializer: item_sz)).as_json(aOptions)
		else
			aObject.as_json(aOptions)
		end
	end

	def to_json(aObject,aOptions)
		jsono = to_jsono(aObject,aOptions)
		result = jsono.to_json
		result
	end
end

module Kojac
	module ModelMethods

		def self.included(aClass)
	    aClass.send :extend, ClassMethods
			aClass.class_eval do
				scope :by_key, ->(aKey,aOperation=nil) {
					key = if respond_to?(:crack_key)
						crack_key(aKey)
					elsif aClass.respond_to?(:crack_key)
						aClass.crack_key(aKey)
					end
					r = key[:resource]
					id = key[:id]
					a = key[:association]
					if id
						where(id: id)
					else
						where('1 = 1')
					end
				}
			end
	  end

		module ClassMethods

			# used by pundit
			def policy_class
				"#{self}Policy".safe_constantize || KojacBasePolicy
			end

			def create_policy(aCurrentUser,aOp=nil)
				policy_class.new(aCurrentUser,self,aOp)
			end

			def active_model_serializer
				"#{self}Serializer".safe_constantize || KojacBaseSerializer
			end

			def crack_key(aKey)
				r,id,a = aKey.split_kojac_key
				result = {}
				result[:original] = aKey
				result[:resource] = r if r
				result[:id] = id if id
				result[:association] = a if a
				result
			end

			def load_by_key(aKey,aOperation=nil)
				r,id,a = aKey.split_kojac_key
				rel = by_key(aKey)
				if id
					result = rel.first
					result.prepare(aKey,aOperation) if result.respond_to? :prepare
				else
					result = rel.all
					result.each do |item|
						item.prepare(aKey,aOperation) if item.respond_to? :prepare
					end
				end
				result
			end
		end

		def unauthorized!(aMessage=nil)
	    raise ::Pundit::NotAuthorizedError, aMessage||"You are not authorized to perform this action"
    end

		def kojac_key
			self.class.to_s.snake_case.pluralize+'__'+self.id.to_s
		end

		def update_permitted_attributes!(aChanges, aPolicy)
			aChanges = KojacUtils.upgrade_hashes_to_params(aChanges)
			p_fields = aPolicy.permitted_fields(:write)
			unauthorized! if p_fields.empty?
			p_fields = aChanges.permit(*p_fields)
			if ::Rails::VERSION::MAJOR <= 3
				assign_attributes(p_fields, :without_protection => true)
			else
				assign_attributes(p_fields)
			end
			save!
		end

		def as_json(options = nil)
			super
		end

	end
end

module Kojac

	class NotFoundError < StandardError
	end

	module ControllerOpMethods

		def self.included(aClass)
	    #aClass.send :extend, ClassMethods
	    # aClass.send :include, ActiveSupport::Callbacks
	    # aClass.send :define_callbacks, :update_op, :scope => [:kind, :name]
	  end

		#module ClassMethods
		#end

		module_function

		public

		def results
			@results ||= {}
		end
		
		def current_ring
			current_user.try(:ring).to_i
		end

		def create_on_association(aItem,aAssoc,aValues,aRing)
			raise "User does not have permission for create on #{aAssoc}" unless aItem.class.ring_can?(aRing,:create_on,aAssoc.to_sym)

			return nil unless ma = aItem.class.reflect_on_association(aAssoc.to_sym)
			a_model_class = ma.klass
			policy = Pundit.policy!(current_user,a_model_class)

			aValues = KojacUtils.upgrade_hashes_to_params(aValues || {})

			case ma.macro
				when :belongs_to
					return nil if !aValues.is_a?(Hash)
					fields = aValues.permit( *policy.permitted_fields(:write) )
					a_model_class.write_op_filter(current_user,fields,aValues) if a_model_class.respond_to? :write_op_filter
					return aItem.send("build_#{aAssoc}".to_sym,fields)
				when :has_many
					aValues = [aValues] if aValues.is_a?(Hash)
					return nil unless aValues.is_a? Array
					aValues.each do |v|
						fields = v.permit( *policy.permitted_fields(:write) )
						new_sub_item = nil
						case ma.macro
							when :has_many
								a_model_class.write_op_filter(current_user,fields,aValues) if a_model_class.respond_to? :write_op_filter
								new_sub_item = aItem.send(aAssoc.to_sym).create(fields)
							else
								raise "#{ma.macro} association unsupported in CREATE"
						end
						merge_model_into_results(new_sub_item)
					end
			end
			#
			#
			#
			#a_value = op[:value][a]        # get data for this association, assume {}
			#if a_value.is_a?(Hash)
			#	a_model_class = ma.klass
			#	fields = a_value.permit( *permitted_fields(:write,a_model_class) )
			#	item.send("build_#{a}".to_sym,fields)
			#	included_assocs << a.to_sym
			#elsif a_value.is_a?(Array)
			#	raise "association collections not yet implemented for create"
			#else
			#	next
			#end
		end

		# Unknown resource :
		# CREATE: already there with given id => error
		# READ: isn't there, or we don't have access => nil
		# UPDATE: isn't there, or we don't have access => nil
		# DESTROY: isn't there, or we don't have access => nil

		def create_op
			ring = current_ring
			op = (self.respond_to?(:op) && self.op || params[:op])
			#op = params[:op] unless self.respond_to? :op
			options = op[:options] || {}
			resource,id,assoc = op['key'].split_kojac_key
			if model_class = KojacUtils.model_class_for_key(resource)
				if assoc  # create operation on an association eg. {verb: "CREATE", key: "order.items"}
					if model_class.ring_can?(ring,:create_on,assoc.to_sym)
						item = KojacUtils.model_for_key(key_join(resource,id))
						ma = model_class.reflect_on_association(assoc.to_sym)
						a_value = op[:value]        # get data for this association, assume {}
						raise "create multiple not yet implemented for associations" unless a_value.is_a?(Hash)

						a_model_class = ma.klass
						policy = Pundit.policy!(current_user,a_model_class)
						p_fields = policy.permitted_fields(:write)
						fields = a_value.permit( *p_fields )
						new_sub_item = nil
						case ma.macro
							when :has_many
								a_model_class.write_op_filter(current_user,fields,a_value) if a_model_class.respond_to? :write_op_filter
								new_sub_item = item.send(assoc.to_sym).create(fields)
							else
								raise "#{ma.macro} association unsupported in CREATE"
						end
						result_key = op[:result_key] || new_sub_item.kojac_key
						merge_model_into_results(new_sub_item)
					else
						error = {
							code: 403,
							status: "Forbidden",
							message: "User does not have permission for #{op[:verb]} operation on #{model_class.to_s}.#{assoc}"
						}
					end
				else    # create operation on a resource eg. {verb: "CREATE", key: "order_items"} but may have embedded association values
					if model_class.ring_can?(:create,ring)
						policy = Pundit.policy!(current_user,model_class)
						p_fields = policy.permitted_fields(:write)

						p_fields = op[:value].permit( *p_fields )
						model_class.write_op_filter(current_user,p_fields,op[:value]) if model_class.respond_to? :write_op_filter
						item = model_class.create!(p_fields)

						options_include = options['include'] || []
						included_assocs = []
						p_assocs = policy.permitted_associations(:write)
						if p_assocs
							p_assocs.each do |a|
								next unless (a_value = op[:value][a]) || options_include.include?(a.to_s)
								create_on_association(item,a,a_value,ring)
								included_assocs << a.to_sym
							end
						end
						item.save!
						result_key = op[:result_key] || item.kojac_key
						merge_model_into_results(item,result_key,:include => included_assocs)
					else
						error = {
							code: 403,
							status: "Forbidden",
							message: "User does not have permission for #{op[:verb]} operation on #{model_class.to_s}"
						}
					end
				end
			else
				error = {
					code: 501,
					status: "Not Implemented",
					message: "model class not found"
				}
			end
			response = {
				key: op[:key],
			  verb: op[:verb],
			}
			if error
				response[:error] = error
			else
				response[:results] = results
				response[:result_key] = result_key
			end
			response
		end

		protected

		def rails_controller?
			self.is_a? ActionController::Base
		end

		def merge_model_into_results(aItem,aResultKey=nil,aOptions=nil)
			ring = current_ring
			aResultKey ||= aItem.g?(:kojac_key)
			results[aResultKey] = (aItem && KojacUtils.to_jsono(aItem,scope: current_user))
			if policy = Pundit.policy!(current_user,aItem)
				aOptions ||= {}
				if included_assocs = aOptions[:include]
					included_assocs = included_assocs.split(',') if included_assocs.is_a?(String)
					included_assocs = [included_assocs] unless included_assocs.is_a?(Array)
					included_assocs.map!(&:to_sym) if included_assocs.is_a?(Array)
					p_assocs = policy.permitted_associations(:read)       # ***
					use_assocs = p_assocs.delete_if do |a|
						if included_assocs.include?(a) and ma = aItem.class.reflect_on_association(a)
							![:belongs_to,:has_many].include?(ma.macro)   # is supported association type
						else
							true  # no such assoc
						end
					end
					use_assocs.each do |a|
						next unless a_contents = aItem.send(a)
						if a_contents.is_a? Array
							contents_h = []
							a_contents.each do |sub_item|
								results[sub_item.kojac_key] = KojacUtils.to_jsono(sub_item,scope: current_user)
							end
						else
							results[a_contents.kojac_key] = KojacUtils.to_jsono(a_contents,scope: current_user)
						end
					end
				end
			end
			results_insert_filter(results,aItem,aResultKey,aOptions) if respond_to?(:results_insert_filter)
			results
		end


		public

		def kojac_setup(aCurrentUser,aOp)
			self.current_user = aCurrentUser if self.respond_to? :current_user
			self.op = aOp if self.respond_to? :op
			self.verb = aOp['verb'] if self.respond_to? :verb
			self.key = aOp['key'] if self.respond_to? :key
			self.value = aOp['value'] if self.respond_to? :value
			self.params = aOp['params'] || {} if self.respond_to? :params
			self.options = aOp['options'] || {} if self.respond_to? :options
			self.error = aOp['error'] if self.respond_to? :error
			self
		end

		def read_op
			op = (self.respond_to?(:op) && self.op || params[:op])
			key = op[:key]
			result_key = nil
			error = nil
			resource,id = key.split '__'
			model = KojacUtils.model_class_for_key(key)
			#raise "model class not found" unless
			if scope = Pundit.policy_scope(current_user, model) || model
				if id   # item
					scope = scope.where(id: id)
					scope = after_scope(scope) if respond_to?(:after_scope)
					if item = scope.first
						#item.prepare(key,op) if item.respond_to? :prepare
						result_key = op[:result_key] || (item && item.kojac_key) || op[:key]
						merge_model_into_results(item,result_key,op[:options])
					else
						result_key = op[:result_key] || op[:key]
						results[result_key] = nil
					end
				else    # collection
					if rails_controller? # deprecated
						items = scope.respond_to?(:all) ? scope.all : scope.to_a
						result_key = op[:result_key] || op[:key]
						results[result_key] = []
						items = after_scope(items) if respond_to?(:after_scope)
					else
						scope = after_scope(scope) if respond_to?(:after_scope)
						items = scope.respond_to?(:all) ? scope.all : scope.to_a
						result_key = op[:result_key] || op[:key]
						results[result_key] = []
					end
					if op[:options] and op[:options][:atomise]==false
						items_json = []
						items_json = items.map {|i| KojacUtils.to_jsono(i,scope: current_user) }
						results[result_key] = items_json
					else
						items.each do |m|
							item_key = m.kojac_key
							results[result_key] << item_key.split_kojac_key[1]
							merge_model_into_results(m,item_key,op[:options])
						end
					end
				end
			else
				error = {
					code: 501,
					status: "Not Implemented",
					message: "model class not found"
				}
			end
			response = {
				key: op[:key],
			  verb: op[:verb],
			}
			if error
				response[:error] = error
			else
				response[:results] = results
				response[:result_key] = result_key
			end
			response
		end

		def update_op
			result = nil
			ring = current_ring
			op = (self.respond_to?(:op) && self.op || params[:op])
			result_key = nil
			model = KojacUtils.model_class_for_key(op[:key].base_key)
			scope = Pundit.policy_scope(current_user, model) || model
			scope = after_scope(scope) if scope && respond_to?(:after_scope)
			if scope and item = scope.load_by_key(op[:key],op)
				#run_callbacks :update_op do
					policy = Pundit.policy!(current_user,item)
					item.update_permitted_attributes!(op[:value], policy)

					associations = policy.permitted_associations(:write)
					associations.each do |k|
						next unless assoc = model.reflect_on_association(k)
						next unless op[:value][k]
						case assoc.macro
							when :belongs_to
								if leaf = (item.send(k) || item.send("build_#{k}".to_sym))
									policy = Pundit.policy!(current_user,leaf)
									leaf.update_permitted_attributes!(op[:value][k], policy)
								end
						end
					end

					result_key = op[:result_key] || (item && item.kojac_key) || op[:key]
					merge_model_into_results(item,result_key,op[:options])

					associations.each do |a|
						next unless assoc_item = item.send(a)
						next unless key = assoc_item.respond_to?(:kojac_key) && assoc_item.kojac_key
						#results[key] = assoc_item
						merge_model_into_results(assoc_item,key)
					end
				#end
			else
				result_key = op[:result_key] || op[:key]
				results[result_key] = nil
			end
			{
				key: op[:key],
			  verb: op[:verb],
			  result_key: result_key,
			  results: results
			}
		end

		def destroy_op
			ring = current_ring
			op = (self.respond_to?(:op) && self.op || params[:op])
			result_key = op[:result_key] || op[:key]
			# item = KojacUtils.model_for_key(op[:key])
			# item.destroy if item
			r,id,a = op[:key].split_kojac_key

			if id
				model = KojacUtils.model_class_for_key(op[:key].base_key)
				scope = Pundit.policy_scope(current_user, model) || model
				scope = after_scope(scope) if scope && respond_to?(:after_scope)
				item = scope.where(id: id).first
				item.destroy if item
			end
			results[result_key] = nil
			{
				key: op[:key],
			  verb: op[:verb],
			  result_key: result_key,
			  results: results
			}
		end

		#def execute_op
		#	puts 'execute_op'
		#end

		def add_op
			ring = current_ring
			op = (self.respond_to?(:op) && self.op || params[:op])
			model = KojacUtils.model_class_for_key(op[:key].base_key)
			raise "ADD only supports associated collections at present eg order.items" unless op[:key].index('.')

			item = KojacUtils.model_for_key(op[:key].base_key)
			assoc = (assoc=op[:key].key_assoc) && assoc.to_sym
			id = op[:value]['id']

			ma = item.class.reflect_on_association(assoc)
			case ma.macro
				when :has_many
					assoc_class = ma.klass
					assoc_item = assoc_class.find(id)
					item.send(assoc) << assoc_item

					#ids_method = assoc.to_s.singularize+'_ids'
					#ids = item.send(ids_method.to_sym)
					#item.send((ids_method+'=').to_sym,ids + [id])
					result_key = assoc_item.kojac_key
					merge_model_into_results(assoc_item)
				else
					raise "ADD does not yet support #{ma.macro} associations"
			end
			{
				key: op[:key],
			  verb: op[:verb],
			  result_key: result_key,
			  results: results
			}
		end

		def remove_op
			ring = current_ring
			op = (self.respond_to?(:op) && self.op || params[:op])
			model = KojacUtils.model_class_for_key(op[:key].base_key)
			raise "REMOVE only supports associated collections at present eg order.items" unless op[:key].key_assoc

			item = KojacUtils.model_for_key(op[:key].base_key)
			assoc = (assoc=op[:key].key_assoc) && assoc.to_sym
			id = op[:value]['id']

			ma = item.class.reflect_on_association(assoc)
			case ma.macro
				when :has_many
					assoc_class = ma.klass
					if assoc_item = item.send(assoc).find(id)
						item.send(assoc).delete(assoc_item)
						result_key = assoc_item.kojac_key
						if (assoc_item.destroyed?)
							results[result_key] = nil
						else
							merge_model_into_results(assoc_item,result_key)
						end
					end
				else
					raise "REMOVE does not yet support #{ma.macro} associations"
			end
			{
				key: op[:key],
			  verb: op[:verb],
			  result_key: result_key,
			  results: results
			}
		end

		def execute_op
			op = (self.respond_to?(:op) && self.op || params[:op])
			resource,action = op[:key].split_kojac_key
			raise "action not given" unless action.is_a? String
			action = rails_controller? ? "execute_#{action}" : "execute__#{action}"
			raise "action #{action} not implemented on #{resource}" unless respond_to? action.to_sym
			result = rails_controller? ? send(action.to_sym,op) : send(action)
			err = rails_controller? ? op[:error] : (respond_to?(:error).to_nil && send(:error))
			if err
				{
					key: op[:key],
				  verb: op[:verb],
					error: err
				}
			else
				result_key = op[:result_key] || op[:key]
				results = op[:results] || {}             # look at op[:results][result_key]. If empty, fill with returned value from action
				results[result_key] = KojacUtils.to_jsono(result,scope: current_user) unless results.has_key? result_key
				{
					key: op[:key],
					verb: op[:verb],
					result_key: result_key,
					results: results
				}
			end
		end
	end
end
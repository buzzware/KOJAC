#require File.expand_path('ring_strong_parameters',File.dirname(__FILE__))

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
		Time.now.to_i
	end
end

module Kojac
	module ModelMethods

		def self.included(aClass)
	    aClass.send :extend, ClassMethods
	  end

		module ClassMethods

			def crack_key(aKey)
				r,id,a = aKey.split_kojac_key
				result = {}
				result[:original] = aKey
				result[:resource] = r if r
				result[:id] = id if id
				result[:association] = a if a
				result
			end

			def by_key(aKey,aOperation=nil)
				key = crack_key(aKey)
				r = key[:resource]
				id = key[:id]
				a = key[:association]
				model = self
				model = self.rescope(model,aOperation) if self.respond_to? :rescope
				if id
					result = model.where(id: id).first
					result.prepare(key,aOperation) if result.respond_to? :prepare
				else
					result = model.all
					result.each do |item|
						item.prepare(key,aOperation) if item.respond_to? :prepare
					end
				end
				result
			end
		end

		def kojac_key
			self.class.to_s.snake_case.pluralize+'__'+self.id.to_s
		end

		def update_permitted_attributes!(aChanges, aRing)
			aChanges = KojacUtils.upgrade_hashes_to_params(aChanges)
			permitted_fields = self.class.permitted_fields(:write, aRing)
			permitted_fields = aChanges.permit(*permitted_fields)
			assign_attributes(permitted_fields, :without_protection => true)
			save!
		end

	end
end

module Kojac

	class NotFoundError < StandardError
	end

	module ControllerOpMethods

		def self.included(aClass)
	    #aClass.send :extend, ClassMethods
	    aClass.send :include, ActiveSupport::Callbacks
	    aClass.send :define_callbacks, :update_op, :scope => [:kind, :name]
	  end

		#module ClassMethods
		#end

		module_function

		public

		attr_accessor :item

		def results
			@results ||= {}
		end

		def deduce_model_class
			KojacUtils.model_class_for_key(self.kojac_resource)
		end

		def kojac_resource
			self.class.to_s.chomp('Controller').snake_case
		end

		def kojac_current_user
			self.current_user
		end

		def current_ring
			kojac_current_user.try(:ring).to_i
		end

		def create_on_association(aItem,aAssoc,aValues,aRing)
			raise "User does not have permission for create on #{aAssoc}" unless aItem.class.permitted_associations(:create,aRing).include?(aAssoc.to_sym)

			return nil unless ma = aItem.class.reflect_on_association(aAssoc.to_sym)
			a_model_class = ma.klass

			aValues = KojacUtils.upgrade_hashes_to_params(aValues || {})

			case ma.macro
				when :belongs_to
					return nil if !aValues.is_a?(Hash)
					fields = aValues.permit( *a_model_class.permitted_fields(:write,aRing) )
					a_model_class.write_op_filter(current_user,fields,aValues) if a_model_class.respond_to? :write_op_filter
					return aItem.send("build_#{aAssoc}".to_sym,fields)
				when :has_many
					aValues = [aValues] if aValues.is_a?(Hash)
					return nil unless aValues.is_a? Array
					aValues.each do |v|
						fields = v.permit( *a_model_class.permitted_fields(:write,aRing) )
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

		def create_op
			ring = current_ring
			op = params[:op]
			options = op[:options] || {}
			model_class = deduce_model_class
			resource,id,assoc = op['key'].split_kojac_key
			if assoc  # create operation on an association eg. {verb: "CREATE", key: "order.items"}
				raise "User does not have permission for #{op[:verb]} operation on #{model_class.to_s}.#{assoc}" unless model_class.permitted_associations(:create,ring).include?(assoc.to_sym)
				item = KojacUtils.model_for_key(key_join(resource,id))
				ma = model_class.reflect_on_association(assoc.to_sym)
				a_value = op[:value]        # get data for this association, assume {}
				raise "create multiple not yet implemented for associations" unless a_value.is_a?(Hash)

				a_model_class = ma.klass
				p_fields = a_model_class.permitted_fields(:write,ring)
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
			else    # create operation on a resource eg. {verb: "CREATE", key: "order_items"} but may have embedded association values
				p_fields = model_class.permitted_fields(:write,ring)
				raise "User does not have permission for #{op[:verb]} operation on #{model_class.to_s}" unless model_class.ring_can?(:create,ring)

				p_fields = op[:value].permit( *p_fields )
				model_class.write_op_filter(current_user,p_fields,op[:value]) if model_class.respond_to? :write_op_filter
				item = model_class.create!(p_fields)

				options_include = options['include'] || []
				included_assocs = []
				p_assocs = model_class.permitted_associations(:write,ring)
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
			end
			{
				key: op[:key],
			  verb: op[:verb],
			  result_key: result_key,
			  results: results
			}
		end

		protected

		def merge_model_into_results(aItem,aResultKey=nil,aOptions=nil)
			ring = current_ring
			aResultKey ||= aItem.kojac_key
			aOptions ||= {}
			results[aResultKey] = aItem.sanitized_hash(ring)
			if included_assocs = aOptions[:include]
				included_assocs = included_assocs.split(',') if included_assocs.is_a?(String)
				included_assocs = [included_assocs] unless included_assocs.is_a?(Array)
				included_assocs.map!(&:to_sym) if included_assocs.is_a?(Array)
				p_assocs = aItem.class.permitted_associations(:read,ring)
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
							results[sub_item.kojac_key] = sub_item.sanitized_hash(ring)
							#contents_h << sub_item.id
						end
						#results[aResultKey] = contents_h
					else
						results[a_contents.kojac_key] = a_contents.sanitized_hash(ring)
					end
				end
			end
		end

		public

		def read_op
			op = params[:op]
			key = op[:key]
			result_key = nil
			resource,id = key.split '__'
			model = deduce_model_class
			scope = Kojac.policy_scope(current_user, model, op) || model
			if id   # item
				if scope
					item = scope.by_key(key,op)
					result_key = op[:result_key] || (item && item.kojac_key) || op[:key]
					merge_model_into_results(item,result_key,op[:options])
				else
					result_key = op[:result_key] || op[:key]
					results[result_key] = null
				end
			else    # collection
				result_key = op[:result_key] || op[:key]
				results[result_key] = []
				if scope
					items = scope.by_key(key,op)
					if op[:options] and op[:options][:atomise]==false
						items_json = []
						items_json = items.map {|i| i.sanitized_hash(current_ring) }
						results[result_key] = items_json
					else
						items.each do |m|
							item_key = m.kojac_key
							results[result_key] << item_key.split_kojac_key[1]
							merge_model_into_results(m,item_key,op[:options])
						end
					end
				end
			end
			{
				key: op[:key],
			  verb: op[:verb],
			  results: results,
			  result_key: result_key
			}
		end

		def update_op
			result = nil
			model = deduce_model_class
			scope = Kojac.policy_scope(current_user, model, op) || model

			ring = current_ring
			op = params[:op]
			result_key = nil
			if self.item = scope.by_key(op[:key],op)

				run_callbacks :update_op do
					item.update_permitted_attributes!(op[:value], ring)

					associations = model.permitted_associations(:write,ring)
					associations.each do |k|
						next unless assoc = model.reflect_on_association(k)
						next unless op[:value][k]
						case assoc.macro
							when :belongs_to
								if leaf = (item.send(k) || item.send("build_#{k}".to_sym))
									#permitted_fields = leaf.class.permitted_fields(:write,ring)
									#permitted_fields = op[:value][k].permit( *permitted_fields )
									#leaf.assign_attributes(permitted_fields, :without_protection => true)
									#leaf.save!
									leaf.update_permitted_attributes!(op[:value][k], ring)
								end
						end
					end

					result_key = item.kojac_key
					results[result_key] = item

					associations.each do |a|
						next unless assoc_item = item.send(a)
						next unless key = assoc_item.respond_to?(:kojac_key) && assoc_item.kojac_key
						results[key] = assoc_item
					end
				end
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
			op = params[:op]
			result_key = op[:result_key] || op[:key]
			item = KojacUtils.model_for_key(op[:key])
			item.destroy if item
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
			op = params[:op]
			model = deduce_model_class
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
			op = params[:op]
			model = deduce_model_class
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
			op = params[:op]
			resource,action = op[:key].split_kojac_key
			raise "action #{action} not implemented on #{resource}" unless respond_to? action.to_sym
			result = send(action.to_sym,op)
			result_key = op[:result_key] || op[:key]
			results = op[:results] || {}             # look at op[:results][result_key]. If empty, fill with returned value from action
			results[result_key] = result unless results.has_key? result_key
			{
				key: op[:key],
			  verb: op[:verb],
			  result_key: result_key,
			  results: results
			}
		end
	end
end
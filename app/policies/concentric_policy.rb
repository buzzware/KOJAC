require 'standard_exceptions'

class ConcentricPolicy

	include ::StandardExceptions::Methods

	class_attribute :filters

  attr_reader :user, :record, :ability

  def initialize(user, record)
	  raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user = user
    @record = record
  end

  def unauthorized!(aMessage=nil)
	  raise Pundit::NotAuthorizedError, aMessage||"You are not authorized to perform this action"
  end

  def self.allow_filter(aOptions=nil,&block)
	  aOptions = {all: true} if !aOptions
	  if rings = aOptions[:ring]
		  rings = [rings] unless rings.is_a? Array
		  aOptions[:ring] = rings.map {|r| Concentric.lookup_ring(r) }
		end
	  if abilities = aOptions[:ability]
		  aOptions[:ability] = [abilities] unless abilities.is_a? Array
	  end
	  if block
		  self.filters ||= []
		  self.filters += [[aOptions,block]]  # double brackets necessary to add an array into the array
		end
  end

	# this could use an alternative field or method in future
  def user_ring
	  user.ring
	end

	def record_class
		record.is_a?(Class) ? record : record.class
	end

	def record_instance
		record.is_a?(Class) ? nil : record
	end

	def apply_filters(aResult)
		if self.class.filters
			self.class.filters.each do |f|
				options, handler = f
				unless options[:all]
					if rings = options[:ring]
						next unless rings.include? user_ring
					end
					if abilities = options[:ability]
						next unless abilities.include? @ability
					end
				end
				aResult = handler.call(self, aResult.clone)   # ring not necessary, use aPolicy.user.ring instead. aAbility not necessary, use aPolicy.ability
			end
			aResult.uniq!
			aResult.sort!
		end
		aResult
	end

	def inner_query_ability(aAbility)
		@ability = aAbility
		internal_server_error! "aAbility must be a string or a symbol" unless aAbility.is_a?(String) or aAbility.is_a?(Symbol)
		aAbility = aAbility.to_s

		case aAbility
			when 'write','read','update','show','edit'
				inner_query_fields(aAbility).length > 0
			when 'create','destroy','index'
				inner_query_resource(aAbility)
			else
				internal_server_error! 'this ability is unknown'
		end
	end

  def inner_query_fields(aAbility=nil)
	  aAbility = @ability = (aAbility || @ability)
	  raise "Ability must be set or given" unless aAbility
	  cls = record.is_a?(Class) ? record : record.class
	  result = cls.permitted(user_ring,aAbility)
	  result = apply_filters(result)
	  result
	end

	def inner_query_resource(aAbility)
		internal_server_error! "aAbility must be a string or a symbol" unless aAbility.is_a?(String) or aAbility.is_a?(Symbol)
		return false unless user_ring and rings_abilities = record_class.respond_to?(:rings_abilities) && record_class.rings_abilities.to_nil
		unauthorized! "identity not given" if !user

		aAbility = aAbility.to_s

		ring_keys = rings_abilities.keys.sort
		ring_keys.each do |i|
			next unless i >= user_ring
			next unless ring_rec = rings_abilities[i]
			#next unless ring_rec.has_key? aAbility.to_sym
			perm = ring_rec[aAbility.to_sym]
			return true if perm==true or perm==:this or perm.is_a?(Array) && !perm.empty?
		end
		false
	end

	def permitted_attributes(aAbility=nil)
		inner_query_fields(aAbility)
	end

  def permitted_fields(aAbility=nil)
	  result = inner_query_fields(aAbility)
	  cls = record.is_a?(Class) ? record : record.class
		result.delete_if { |f| cls.reflections.has_key? f }
		result
	end

	def permitted_associations(aAbility=nil)
	  result = inner_query_fields(aAbility)
	  cls = record.is_a?(Class) ? record : record.class
		result.delete_if { |f| !cls.reflections.has_key? f }
		result
	end

	def defaults
		{}
	end

	def valid?
		true
	end

  # kojac methods
  def create?
	  inner_query_ability(:create) && valid?
  end

  def read?
	  inner_query_ability(:read)
  end

  def write?
	  inner_query_ability(:write) && valid?
  end

  def destroy?
	  inner_query_ability(:destroy)
  end

  # rails methods
  def index?
	  inner_query_ability(:read)
  end

  def show?
	  inner_query_ability(:read)
  end

  def new?
	  inner_query_ability(:create)
  end

  def update?
	  inner_query_ability(:write)
  end

  def edit?
	  inner_query_ability(:write)
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

end

class KojacBasePolicy

	class_attribute :filters

  attr_reader :user, :record, :op

  def initialize(user, record, op=nil)
	  raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user = user
    @record = record
	  @op = op
  end

  def unauthorized!(aMessage=nil)
	  raise Pundit::NotAuthorizedError, aMessage||"You are not authorized to perform this action"
  end

	def self.ability_from_op(aOp)
	  return nil unless aOp
	  case aOp[:verb]
			when 'CREATE'
			when 'UPDATE'
				:write
			when 'READ'
				:read
			when 'ADD'
				:add
			when 'REMOVE'
				:remove
			when 'CREATE_ON'
				:create_on
		end
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

  def query_ring
	  user.ring
  end

	def apply_filters(aResult, aAbility)
		if self.class.filters
			self.class.filters.each do |f|
				options, handler = f
				unless options[:all]
					if rings = options[:ring]
						next unless rings.include? query_ring
					end
					if abilities = options[:ability]
						next unless abilities.include? aAbility
					end
				end
				aResult = handler.call(self, aResult.clone, query_ring, aAbility)
			end
			aResult.uniq!
			aResult.sort!
		end
		aResult
	end

  def inner_query_fields(aAbility)
	  cls = record.is_a?(Class) ? record : record.class
	  result = cls.permitted(query_ring,aAbility)
	  result = apply_filters(result, aAbility)
	  result
  end

	def inner_query_record(aAbility)
		inner_query_fields(aAbility).length > 0
	end

	def permitted_attributes(aAbility=nil)
		#raise "Ability from op no longer supported" if !aAbility && @op && @op[:verb]
		aAbility ||= self.class.ability_from_op(@op)
		raise "ability not given" unless aAbility
		fields = inner_query_fields(aAbility)

		#cls = record.is_a?(Class) ? record : record.class
		#fields = cls.permitted(query_ring,aAbility)
		#result = apply_filters(fields,aAbility)
		fields
	end

  def permitted_fields(aAbility=nil)
	  result = permitted_attributes(aAbility)
	  cls = record.is_a?(Class) ? record : record.class
		result.delete_if { |f| cls.reflections.has_key? f }
		result
	end

	def permitted_associations(aAbility=nil)
	  result = permitted_attributes(aAbility)
	  cls = record.is_a?(Class) ? record : record.class
		result.delete_if { |f| !cls.reflections.has_key? f }
		result
	end

  # kojac methods
  def create?
	  inner_query_record(:create)
  end

  def read?
	  inner_query_record(:read)
  end

  def write?
	  inner_query_record(:write)
  end

  def destroy?
	  inner_query_record(:destroy)
  end

  # rails methods
  def index?
	  inner_query_record(:read)
  end

  def show?
	  inner_query_record(:read)
  end

  def new?
	  inner_query_record(:create)
  end

  def update?
	  inner_query_record(:write)
  end

  def edit?
	  inner_query_record(:write)
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

end


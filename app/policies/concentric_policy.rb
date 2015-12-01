class ConcentricPolicy

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

  def inner_query_fields(aAbility=nil)
	  aAbility = @ability = (aAbility || @ability)
	  raise "Ability must be set or given" unless aAbility
	  cls = record.is_a?(Class) ? record : record.class
	  result = cls.permitted(user_ring,aAbility)
	  result = apply_filters(result)
	  result
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

	def inner_query_ability(aAbility)
		@ability = aAbility
		inner_query_fields.length > 0
	end

  # kojac methods
  def create?
	  inner_query_ability(:create)
  end

  def read?
	  inner_query_ability(:read)
  end

  def write?
	  inner_query_ability(:write)
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

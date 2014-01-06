class KojacPolicy
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

  #def self.write_op_filter(aCurrentUser,aSafeFields,aSourceFields)
		#	ring = aCurrentUser.ring
		#	has_owner = !!self.column_names.include?('owner_id')
		#	has_dealership = !!self.column_names.include?('dealership_id')
		#	# default to user
		#	if ring <= SALES_RING
		#		aSafeFields['owner_id'] ||= aCurrentUser.owner_id if has_owner
		#		aSafeFields['dealership_id'] ||= aCurrentUser.dealership_id if has_dealership
		#	end
		#	if ring > SYSADMIN_RING
		#		unauthorized! if aSafeFields['owner_id'] != aCurrentUser.owner_id if has_owner
		#	end
		#	if ring > OWNER_ADMIN_RING
		#		unauthorized! if aSafeFields['dealership_id'] != aCurrentUser.dealership_id if has_dealership
		#	end
		#end


  def read?
	  record.class.ring_can?(user.ring,:read)
  end

  def manage?
	  record.class.ring_can?(user.ring,:write)
  end

  def index?
	  record.class.ring_can?(user.ring,:read)
  end

  def show?
	  record.class.ring_can?(user.ring,:read)
  end

  def create?
	  record.class.ring_can?(user.ring,:create)
  end

  def new?
	  record.class.ring_can?(user.ring,:create)
  end

  def update?
	  record.class.ring_can?(user.ring,:write)
  end

  def edit?
	  record.class.ring_can?(user.ring,:write)
  end

  def destroy?
	  record.class.ring_can?(user.ring,:destroy)
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

	def permitted_attributes
		ability = case @op[:verb]
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
		record.class.permitted(user.ring,ability)
	end
end


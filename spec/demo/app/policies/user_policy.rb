class UserPolicy < KojacBasePolicy

	def is_self?
		user.id == record.id
	end

	def query_ring
		user.ring
	end

	def write?
	  return user.ring <= ADMIN_RING if @record==User
	  raise "Bad record given" unless record.is_a? User
	  return ((user.ring <= SYSADMIN_RING) || is_self? || (
		  (user.ring <= record.ring) && (
				(user.ring <= ADMIN_RING) && (!user.owner_id || (record.owner_id == user.owner_id))
			)
	  ))
  end

	def permitted_attributes(aAbility=nil)
		case aAbility
			when :write
				return [] unless write?
			when :read
				return [] unless read?
		end

		result = super(aAbility)

		if is_self? && user.ring <= USER_RING
			case aAbility
				when :write
					result = (result | (User::PUBLIC_FIELDS + User::PRIVATE_FIELDS)).sort
				when :read
					result = (result | (User::PRIVATE_FIELDS)).sort
			end
		end
		result
	end

end
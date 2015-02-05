class UserPolicy < KojacBasePolicy

	def is_self?
		user.id == record.id
	end

	# def write?
	#   return query_ring <= ADMIN_RING if @record==User
	#   raise "Bad record given" unless record.is_a? User
	#   return ((query_ring <= SYSADMIN_RING) || is_self? || (
	#
	#   ))
	# end

	allow_filter do |aPolicy,aResult,aRing,aAbility|
		if aRing <= SYSADMIN_RING     # sysadmin can do all, so pass through
			aResult
		elsif (aPolicy.user.owner_id and aPolicy.record.owner_id != aPolicy.user.owner_id)  # user has a ring that doesn't match record
			aResult = []
		elsif aRing > USER_RING       # outside of user, can't do anything
			aResult
		else
			if aPolicy.is_self? or (aRing < aPolicy.record.ring and aRing <= ADMIN_RING)    # can admin if self or admin and lower rank
				case aAbility
					when :write
						aResult += User::PUBLIC_FIELDS + User::PRIVATE_FIELDS
					when :read
						aResult += User::PRIVATE_FIELDS
				end
			end
			aResult
		end
	end

	# allow_filter ring: :guest_admin, ability: :write do |aPolicy,aResult,aRing,aAbility|
	# 	aResult && aPolicy.is_self?
	# end
	#
	# allow_filter ability: [:create, :write] do |aPolicy,aRing,aAbility,aFields,aResult|
	# 	# logic here to set aResult
	# 	aResult
	# end
	#
	# # prevent guest_admin from creating or writing Users, even though  outer rings can
	# allow_filter ring: :guest_admin, ability: [:create, :write] do |aUser,aRecord,aAbility,aFields,aResult|
	# 	false
	# end

	# def permitted_attributes(aAbility=nil)
	# 	case aAbility
	# 		when :write
	# 			return [] unless write?
	# 		when :read
	# 			return [] unless read?
	# 	end
	#
	# 	result = super(aAbility)
	#
	# 	if is_self? && query_ring <= USER_RING
	# 		case aAbility
	# 			when :write
	# 				result = (result | (User::PUBLIC_FIELDS + User::PRIVATE_FIELDS)).sort
	# 			when :read
	# 				result = (result | (User::PRIVATE_FIELDS)).sort
	# 		end
	# 	end
	# 	result
	# end

end
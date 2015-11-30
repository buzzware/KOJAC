class UserPolicy < KojacBasePolicy

	def is_self?
		user.id == record.id
	end

	allow_filter do |p,fields|
		ring = p.user.ring
		if ring <= SYSADMIN_RING     # sysadmin can do all, so pass through
			fields
		elsif (p.user.owner_id and p.record.owner_id != p.user.owner_id)  # user has a ring that doesn't match record
			fields = []
		elsif ring > USER_RING       # outside of user, can't do anything
			fields
		else
			if p.is_self? or (ring < p.record.ring and ring <= ADMIN_RING)    # can admin if self or admin and lower rank
				case p.ability
					when :write
						fields += User::PUBLIC_FIELDS + User::PRIVATE_FIELDS
					when :read
						fields += User::PRIVATE_FIELDS
				end
			end
			fields
		end
	end

	# allow_filter ring: :guest_admin, ability: :write do |aPolicy,aFields|
	# 	aPolicy.is_self? ? aFields : []
	# end
	#
	# allow_filter ability: [:create, :write] do |aPolicy,aFields|
	# 	# logic here to set aResult
	# 	aFields
	# end
	#
	# # prevent guest_admin from creating or writing Users, even though  outer rings can
	# allow_filter ring: :guest_admin, ability: [:create, :write] do |aPolicy,aFields|
	# 	[]
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
	# 	if is_self? && user_ring <= USER_RING
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
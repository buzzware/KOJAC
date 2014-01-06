class UserPolicy < KojacBasePolicy

	def is_self?
		user.id == record.id
	end

	def query_ring
		@query_ring ||= is_self? ? [user.ring,Concentric.lookup_ring(:self)].min : user.ring
	end

end
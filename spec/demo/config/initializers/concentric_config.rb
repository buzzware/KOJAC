ActiveRecord::Base.send(:include, ActiveModel::ForbiddenAttributesProtection)

SYSADMIN_RING = 0
ADMIN_RING = 10
SELF_RING = 25
USER_RING = 30
PUBLIC_RING = 100
Concentric.config = {
	ring_names: { sysadmin: SYSADMIN_RING, admin: ADMIN_RING, self: SELF_RING, user: USER_RING, public: PUBLIC_RING }
}

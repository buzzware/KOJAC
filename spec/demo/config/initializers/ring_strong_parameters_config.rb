ActiveRecord::Base.send(:include, ActiveModel::ForbiddenAttributesProtection)

SYSADMIN_RING = 0
OWNER_ADMIN_RING = 10
DEALERSHIP_ADMIN_RING = 20
SALES_RING = 30
PUBLIC_RING = 100
RingStrongParameters.config = {
	ring_names: { sysadmin: SYSADMIN_RING, owner_admin: OWNER_ADMIN_RING, dealership_admin: DEALERSHIP_ADMIN_RING, sales: SALES_RING, public: PUBLIC_RING }
}

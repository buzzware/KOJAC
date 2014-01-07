class User < ActiveRecord::Base

	include Concentric::Model
	include ::Kojac::ModelMethods

	PUBLIC_FIELDS = [
		:first_name,
		:last_name,
	]

	PRIVATE_FIELDS = [
		:email,
		:middle_names,
		:dob
	]

	ADMIN_FIELDS = [
		:ring
	]

	READ_ONLY_FIELDS = [
		:id,
		:owner_id,
		:created_at,
		:updated_at
	]

 	ALL_FIELDS = PUBLIC_FIELDS + PRIVATE_FIELDS + ADMIN_FIELDS + READ_ONLY_FIELDS

	ring :user, :read => PUBLIC_FIELDS
	#ring :user, :write => []

	ring :admin, :read => ALL_FIELDS
	ring :admin, :write => PUBLIC_FIELDS + PRIVATE_FIELDS + ADMIN_FIELDS

end

class User < ActiveRecord::Base

	include RingStrongParameters::Model
	include ::Kojac::ModelMethods

	PUBLIC_FIELDS = [
		:email,
		:first_name,
		:middle_names,
		:last_name,
		:dob
	]

	PROTECTED_FIELDS = [
		:ring
	]

	READ_ONLY_FIELDS = [
		:id
	]

	INTERNAL_FIELDS = [
		:created_at,
		:updated_at
	]

 	ALL_FIELDS = PUBLIC_FIELDS + PROTECTED_FIELDS + READ_ONLY_FIELDS + INTERNAL_FIELDS
	READABLE_FIELDS = PUBLIC_FIELDS + PROTECTED_FIELDS + READ_ONLY_FIELDS

	ring :user, :read => PUBLIC_FIELDS + PROTECTED_FIELDS + READ_ONLY_FIELDS
	ring :user, :write => PUBLIC_FIELDS

	ring :admin, :read => INTERNAL_FIELDS
	ring :admin, :write => PROTECTED_FIELDS

end

class User < ActiveRecord::Base

	include RingStrongParameters::Model
	include ::Kojac::ModelMethods

	ADMIN_FIELDS = [
    :ring
  ]

	DETAILS_FIELDS = [
		:email,
		:first_name,
		:middle_names,
		:last_name,
		:dob
	]

  INTERNAL_FIELDS = [
    :id,
    :created_at,
    :updated_at
  ]

 	ALL_FIELDS = ADMIN_FIELDS + DETAILS_FIELDS + INTERNAL_FIELDS

	ring :sales, :read => ALL_FIELDS

end

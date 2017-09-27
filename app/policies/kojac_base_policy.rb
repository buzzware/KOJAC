class KojacBasePolicy < ConcentricPolicy

	def inner_query_ability(aAbility)
	  result = super
    case aAbility
	    when :create,:write,:destroy
		    result &&= allow_write?
    end
    result
  end

	# Override this and check that this freshly loaded record is allowed to be written
	# This is where you check the values of fields eg. dealership_id to make sure the user has the right to change the record *before* changing it.
	# This further limits the user within the read scope to just the objects it can write.
  def allow_write?
    true
  end

	# Override this and check values are valid eg.
	# record.owner_id==user.owner_id unless adminOf?
	# and return boolean
	# This checks any changes *after* they have been made, before they are saved.
	def valid?
		true
	end

end

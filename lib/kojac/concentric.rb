#concentric
#
#Assists implementation of ring level security (http://en.wikipedia.org/wiki/Ring_(computer_security)) with Rails 4 (or Rails 3 with gem) Strong Parameters.
#
#Ring Level Security is a simpler alternative to Role Based Security. Rings are arranged in a concentric hierarchy from most-privileged innermost Ring 0 to the least privileged highest ring number. Users have their own ring level which gives them access to that ring and below.
#
#For example, a sysadmin could have Ring 0, a website manager ring 1, a customer ring 2, and anonymous users ring 3. A customer would have all the capabilities of anonymous users, and more. Likewise, a website manager has all the capabilities of a customer, and more etc.
#
#This inheritance of capabilities of outer rings, and the simple assigning of users to rings, makes security rules less repetitive and easier to write and maintain, minimising dangerous mistakes.
#
#This gem does not affect or replace or prevent the standard strong parameters methods from being used in parallel, it merely generates arguments for the standard strong parameters methods.
#
#
#
#BASIC_FIELDS = [:name, :address]
#
#class Deal
#  ring 1, :write, BASIC_FIELDS
#  ring 1, :write, :phone
#  ring 1, :delete
#  ring 2, :read, BASIC_FIELDS
#end
#
#
#class DealsController
#
#  def update
#    ring_fields(:write,model)
#    if ring_can(:write,model,:name)
#    if ring_can(:delete,model)
#    model.update(params.permit( ring_fields(:write,model) ))
#  end
#
#end



class Concentric

	cattr_accessor :config

	def self.lookup_ring(aRingName)
		return nil if !aRingName
		return aRingName if aRingName.is_a?(Fixnum)
		if ring_names = Concentric.config[:ring_names]
			return ring_names[aRingName.to_sym]
		else
			return nil
		end
	end

	def self.ring_name(aRing)
		ring_names = Concentric.config[:ring_names]
		ring_names.key(aRing)
	end

	def self.ring_text(aRing)
		return 'none' if !aRing
		ring_name(aRing).to_s.humanize
	end
end


# see http://yehudakatz.com/2009/11/12/better-ruby-idioms/ re class and instance methods and modules

module Concentric::Model

	def self.included(aClass)
		aClass.cattr_accessor :rings_abilities
    aClass.rings_abilities = []  # [1] => {read: [:name,:address], delete: true}
    aClass.send :extend, ClassMethods
  end

	def sanitized_hash(aRing)
		p_fields = self.class.permitted_fields(:read, aRing)
		self.attributes.filter_include(p_fields)
	end

	module ClassMethods

		# supports different formats :
		# ring :sales, :write => [:name,:address]   ie. sales can write the name and address fields
		# ring :sales, :read                        ie. sales can read this model
		# ring :sales, [:read, :create, :destroy]   ie. sales can read, create and destroy this model
		def ring(aRing,aAbilities)
			aRing = Concentric.lookup_ring(aRing)
			raise "aRing must be a number or a symbol defined in Concentric.config.ring_names" if !aRing.is_a?(Fixnum)
			raise "aAbilities must be a Hash" unless aAbilities.is_a? Hash # eg. :write => [:name,:address]

			ring_rec = self.rings_abilities[aRing]
				aAbilities.each do |abilities,fields|
					abilities = [abilities] unless abilities.is_a?(Array)
					fields = [fields] unless fields.is_a?(Array)
				next if fields.empty?
					abilities.each do |a|
						a = a.to_sym
					ring_rec ||= {}
					if fields==[:this]
						ring_rec[a] = true unless ring_rec[a].to_nil
					else
						ring_fields = ring_rec[a]
						ring_fields = [] unless ring_fields.is_a? Array
						ring_fields = ring_fields + fields.map(&:to_sym)
						ring_fields.uniq!
						ring_fields.sort!
						ring_rec[a] = ring_fields
					end
				end
				self.rings_abilities[aRing] = ring_rec
			end
		end

		# returns properties that this ring can use this ability on
		# !!! should reverse order of parameters
		def permitted(aAbility,aRing)
			aRing = Concentric.lookup_ring(aRing)
			raise "aRing must be a number or a symbol defined in Concentric.config.ring_names" if !aRing.is_a?(Fixnum)
			return [] unless aRing and rings_abilities = self.respond_to?(:rings_abilities) && self.rings_abilities.to_nil

			fields = []
			aRing.upto(rings_abilities.length-1) do |i|
				next unless ring_rec = rings_abilities[i]
				if af = ring_rec[aAbility.to_sym]
					next if af==true
					fields += af if af.is_a?(Array)
				end
			end
			fields.uniq!
			fields.sort!
			fields
		end

		# !!! should reverse order of parameters
		def permitted_fields(aAbility, aRing)
			result = self.permitted(aAbility, aRing)
			result.delete_if { |f| self.reflections.has_key? f }
			result
		end

		# !!! should reverse order of parameters
		def permitted_associations(aAbility, aRing)
			result = self.permitted(aAbility, aRing)
			result.delete_if { |f| !self.reflections.has_key?(f) }
			result
		end

		# Query
		def ring_can?(aRing,aAbility,aFields=nil)
			if aFields
				pf = permitted(aAbility,aRing)
				if aFields.is_a? Array
					return (aFields - pf).empty?
				else
					return pf.include? aFields
				end
			end

			aRing = Concentric.lookup_ring(aRing)
			return [] unless aRing and rings_abilities = self.respond_to?(:rings_abilities).to_nil && self.rings_abilities

			aRing.upto(rings_abilities.length-1) do |i|
				next unless ring_rec = rings_abilities[i]
				return true if ring_rec[aAbility.to_sym].to_nil
			end
			return false
		end

	end

end

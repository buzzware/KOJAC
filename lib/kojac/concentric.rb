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

# Update: 2015-03-26
#
# * Extracted ConcentricPolicy from Kojac
# * Concentric is now a way of creating Pundit policies based on ConcentricPolicy. It allows shorthand ring security for
# simple scenarios, then allow_filter for refinement and arbitrary complex logic to be implemented
# * Concentric works on the simple idea that there are 4 basic abilities: read, write, create and delete.
# * Read and write apply primarily to fields; create and delete apply to records.
# * Creating a record requires the ability to create the record, then normally you require the ability to write some fields.
# * In order to read a record, you need the ability to read at least one field
# * In order to write to a record, you need the ability to write at least one field
# * In order to delete a record, you need the ability to delete the record
# * With Concentric you first use the ring and
#
# implement Pundit Policy classes and methods (eg. update? show?) by querying these 4 abilities

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

	module ClassMethods

		# supports different formats :
		# allow :sales, :write => [:name,:address]   ie. sales can write the name and address fields
		# allow :sales, :read                        ie. sales can read this model
		# allow :sales, [:read, :create, :destroy]   ie. sales can read, create and destroy this model
		def allow(aRing,aAbilities)
			#aRing.each {|r| ring(r,aAbilities)} and return if aRing.is_a? Array shouldn't need this because of ring system
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

		# deprecated
		def ring(aRing,aAbilities)
			allow(aRing,aAbilities)
		end

		# returns properties that this ring can use this ability on
		def permitted(aRing,aAbility)
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

		# Query
		# aFields specifies fields you require to act on
		# This is no longer used by KojacBasePolicy because it does not observe its filters that operate on fields. It may still provide a faster check when there are no filters applied
		def allowed?(aRing,aAbility,aFields=nil)
			if aFields
				pf = permitted(aRing,aAbility)
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

		# deprecated
		def ring_can?(aRing,aAbility,aFields=nil)
			allowed?(aRing,aAbility,aFields)
		end

	end

end


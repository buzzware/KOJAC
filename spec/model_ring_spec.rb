require 'spec_helper'

describe "Simple Item1 rings" do

	class Item1 < ActiveRecord::Base
		include RingStrongParameters::Model

		ring 3, :write => [:name,:address]
		ring 3, :read => [:name,:address,:member_code]
	end


  it "can specify ring fields" do
	  Item1.rings_fields.should == [
		  nil, 
		  nil, 
		  nil, 
		  {:write=>[:address, :name], :read=>[:address, :member_code, :name]}
	  ]
	  Item1.rings_abilities.should == []
  end
end

describe "Item2 rings with abilities" do

	class Item2 < ActiveRecord::Base
		include RingStrongParameters::Model

		ring 2, [:write,:delete]
		ring 3, :write => [:name,:address]
		ring 3, :read => [:name,:address,:member_code]
		ring 4, :read
	end


  it "can specify ring fields" do
	  Item2.rings_fields.should == [
		  nil, 
		  nil, 
		  nil, 
		  {:write=>[:address, :name], :read=>[:address, :member_code, :name]}
	  ]
	  Item2.rings_abilities.should == [
		  nil,
	    nil,
	    [:delete,:write],
	    nil,
	    [:read]
	  ]
  end
end


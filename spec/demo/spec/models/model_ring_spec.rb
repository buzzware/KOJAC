require 'spec_helper'

describe "Simple Item1 rings" do

	class Item1 < ActiveRecord::Base
		include Concentric::Model

		ring 3, :write => [:name,:address]
		ring 3, :read => [:name,:address,:member_code]
	end


  it "can specify ring fields" do
	  Item1.rings_abilities.should == {
		  3 => {:write=>[:address, :name], :read=>[:address, :member_code, :name]}
	  }
  end
end

describe "Item2 rings with abilities" do

	class Item2 < ActiveRecord::Base
		include Concentric::Model

		ring 2, [:delete] => :this
		ring 3, :write => [:name,:address]
		ring 3, :read => [:name,:address,:member_code]
	end


  it "can specify ring fields" do
	  Item2.rings_abilities.should == {
	    2 => {:delete=>true},
	    3 => {:write=>[:address, :name], :read=>[:address, :member_code, :name]}
	  }
  end
end


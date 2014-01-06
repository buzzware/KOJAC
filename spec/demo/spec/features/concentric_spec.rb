require 'spec_helper'

describe "ConcentricTestModel" do

	before(:all) do
		@original_config = Concentric.config
		Concentric.config = {
			ring_names: {
				master: 0,
				boss: 10,
				pleb: 30,
				anyone: 100
			}
		}
	end

	after(:all) do
		Concentric.config = @original_config
	end

	it "attributes described should be available in outer rings" do
		class ConcentricTestModel < ActiveRecord::Base
			include Concentric::Model

			ring :pleb, read: [:name,:address]
			ring :pleb, read: [:dob]
			ring :boss, read: [:next_of_kin]

			ring :boss, transmogrify: []
			ring :boss, eliminate: :this

			ring :pleb, [:cough,:sneeze] => [:desk,:outside]
		end

		ConcentricTestModel.permitted(:pleb,:read).should == [:address,:dob,:name]
		ConcentricTestModel.permitted(:master,:read).should == [:address,:dob,:name,:next_of_kin]
		ConcentricTestModel.permitted(:anyone,:read).should == []
		ConcentricTestModel.ring_can?(:pleb,:read).should == true
		ConcentricTestModel.ring_can?(:master,:read).should == true
		ConcentricTestModel.ring_can?(:anyone,:read).should == false

		ConcentricTestModel.ring_can?(:pleb,:transmogrify).should == false
		ConcentricTestModel.ring_can?(:boss,:transmogrify).should == false
		ConcentricTestModel.ring_can?(:master,:transmogrify).should == false

		ConcentricTestModel.ring_can?(:pleb,:eliminate).should == false
		ConcentricTestModel.ring_can?(:boss,:eliminate).should == true
		ConcentricTestModel.ring_can?(:master,:eliminate).should == true

		ConcentricTestModel.ring_can?(:pleb,:cough).should == true
		ConcentricTestModel.ring_can?(:pleb,:sneeze).should == true
		ConcentricTestModel.ring_can?(:boss,:cough).should == true
		ConcentricTestModel.ring_can?(:boss,:sneeze).should == true
		ConcentricTestModel.ring_can?(:pleb,:cough,:outside).should == true
		ConcentricTestModel.ring_can?(:pleb,:cough,:desk).should == true
		ConcentricTestModel.ring_can?(:pleb,:cough,[:desk,:outside]).should == true
		ConcentricTestModel.ring_can?(:pleb,:cough,:lunch_room).should == false

		ConcentricTestModel.permitted(:pleb,:cough).should == [:desk,:outside]
		ConcentricTestModel.permitted(:pleb,:sneeze).should == [:desk,:outside]
	end

end

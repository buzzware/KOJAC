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

	it "allow_filter enables custom rules despite heirarchy" do
		class TestUser < ActiveRecord::Base
			self.table_name = 'users'

			include Concentric::Model

			ring :pleb, [:read,:write] => [:name,:address]
			ring :pleb, write: :password
			ring :boss, [:read,:write] => [:notes]
		end

		class TestUserPolicy < KojacBasePolicy
			allow_filter ability: :write, ring: :boss do |p,fields|   # boss can't write other people's passwords
				fields -= [:password] if p.user.id != p.record.id
				fields
			end
			allow_filter do |p,fields|   # boss can't write other people's passwords
				fields = [] if p.user.id != p.record.id and p.user.ring >= p.record.ring and p.user.ring >= Concentric.lookup_ring(:master)
				fields
			end
		end

		TestUser.permitted(:pleb,:read).should == [:address,:name]
		TestUser.permitted(:boss,:read).should == [:address,:name,:notes]
		TestUser.permitted(:pleb,:write).should == [:address,:name,:password]
		TestUser.permitted(:boss,:write).should == [:address,:name,:notes,:password] # permitted is a concentric method!
		anyone = TestUser.create!(
			ring: Concentric.lookup_ring(:anyone),
			first_name: Faker::Name.first_name,
			last_name:  Faker::Name.last_name,
	    email: Faker::Internet.email
		)
		pleb = TestUser.create!(
			ring: Concentric.lookup_ring(:pleb),
			first_name: Faker::Name.first_name,
			last_name:  Faker::Name.last_name,
	    email: Faker::Internet.email
		)
		pleb2 = TestUser.create!(
			ring: Concentric.lookup_ring(:pleb),
			first_name: Faker::Name.first_name,
			last_name:  Faker::Name.last_name,
	    email: Faker::Internet.email
		)
		boss = TestUser.create!(
			ring: Concentric.lookup_ring(:boss),
			first_name: Faker::Name.first_name,
			last_name:  Faker::Name.last_name,
	    email: Faker::Internet.email
		)
		master = TestUser.create!(
			ring: Concentric.lookup_ring(:master),
			first_name: Faker::Name.first_name,
			last_name:  Faker::Name.last_name,
	    email: Faker::Internet.email
		)
		TestUserPolicy.new(pleb,pleb).permitted_attributes(:write).should == [:address,:name,:password]
		TestUserPolicy.new(pleb,pleb2).permitted_attributes(:write).should == []
		TestUserPolicy.new(boss,pleb).permitted_attributes(:write).should == [:address,:name,:notes]
		TestUserPolicy.new(boss,boss).permitted_attributes(:write).should == [:address,:name,:notes,:password]
		TestUserPolicy.new(boss,master).permitted_attributes(:write).should == []
		TestUserPolicy.new(master,boss).permitted_attributes(:write).should == [:address,:name,:notes,:password]
		TestUserPolicy.new(master,pleb).permitted_attributes(:write).should == [:address,:name,:notes,:password]
		TestUserPolicy.new(master,master).permitted_attributes(:write).should == [:address,:name,:notes,:password]
	end


end

require 'spec_helper'

describe "serialization" do

	it "should serialize array" do
		user = FactoryGirl.create(:user)
		jsons = KojacUtils.to_json([1,2,3],scope: user)
		jsons.should == '[1,2,3]'
	end

	it "should serialize number" do
		user = FactoryGirl.create(:user)
		jsons = KojacUtils.to_json(5,scope: user)
		jsons.should == '5'
	end

	it "should serialize object" do
		user = FactoryGirl.create(:user)
		jsons = KojacUtils.to_json({a: 1, b: 2},scope: user)
		jsons.should == '{"a":1,"b":2}'
	end

	#it "should serialize Deal" do
	#	user = FactoryGirl.create(:user)
	#	deal = FactoryGirl.create(:deal, user: user)
	#	jsons = KojacUtils.to_json(deal,scope: user)
	#	jsono = JSON.parse jsons
	#	jsono['trade_in_price'].should be > 0
	#	jsono['cash_deposit'].should be > 0
	#	jsono['other_cost'].should be > 0
	#end

	it "to_jsono should convert embedded model to a hash" do
		user = FactoryGirl.create(:user)
		user2 = FactoryGirl.create(:user)

		embed = {user: user2}
		jsono =  KojacUtils.to_jsono(embed,scope: user)
		jsono['user'].class.should == Hash
	end

	it "model serialized inside a hash should give the same fields as when serialized directly" do
		user = FactoryGirl.create(:user)
		user2 = FactoryGirl.create(:user)

		embed = {user: user2}
		embed_jsons = KojacUtils.to_json(embed,scope: user)
		embed_jsono = JSON.parse embed_jsons

		direct_jsons = KojacUtils.to_json(user2,scope: user)
		direct_jsono = JSON.parse direct_jsons

		embed_jsono['user'].should == direct_jsono
	end

	#it "model serialized deeply inside a structure should give the same fields as when serialized directly" do
	#	user = FactoryGirl.create(:user)
	#	user2 = FactoryGirl.create(:user)
	#
	#	embed = {user: user2}
	#	embed_jsons = KojacUtils.to_json(embed,scope: user)
	#	embed_jsono = JSON.parse embed_jsons
	#
	#	direct_jsons = KojacUtils.to_json(user2,scope: user)
	#	direct_jsono = JSON.parse direct_jsons
	#
	#	embed_jsono['user'].should == direct_jsono
	#end

	it "should test models embedded in an Array" do
		user = FactoryGirl.create(:user)
		user2 = FactoryGirl.create(:user)

		embed = [user2]
		embed_jsons = KojacUtils.to_json(embed,scope: user)
		embed_jsono = JSON.parse embed_jsons

		direct_jsons = KojacUtils.to_json(user2,scope: user)
		direct_jsono = JSON.parse direct_jsons

		embed_jsono[0].should == direct_jsono
	end

	it "should test models embedded in an HashWithIndifferentAccess"

end

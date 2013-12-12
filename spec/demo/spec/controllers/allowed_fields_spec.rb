require 'spec_helper'

describe KojacController do

	before(:each) do
		@user = FactoryGirl.create(:user, ring: 3)
		ApplicationController.any_instance.stub(:current_user).and_return(@user)
	end

	it 'should do something' do
		@user2 = FactoryGirl.create(:user)
		read_op = {
			verb: 'READ',
			key: 'users'
		}
		content = {
			options: {},
			ops: [
				read_op
			]
		}
		request.accept = "application/json"
		post :receive, format: :json, kojac: content

		output = JSON.parse response.body
		output['ops'].should be_is_a Array
		output['ops'].length.should == 1
		op = output['ops'].first
		op['verb'].should == read_op[:verb]
		op['key'].should == read_op[:key]
		op['results'].class.should == Hash
		user_key = "users__#{@user.id}"
		user2_key = "users__#{@user2.id}"

		op['results'].keys.sort.should == ["users",user_key,user2_key].sort
		op['results']['users'].should == [@user.id,@user2.id]
		op['results'][user_key].filter_include(%w(id first_name last_name)).should == {
			'id' => @user.id,
			'first_name' => @user.first_name,
			'last_name' => @user.last_name
		}
		op['results'][user2_key].filter_include(%w(id first_name last_name)).should == {
			'id' => @user2.id,
			'first_name' => @user2.first_name,
			'last_name' => @user2.last_name
		}
		op['result'].should_not be
	end
end

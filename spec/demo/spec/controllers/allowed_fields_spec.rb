require 'spec_helper'

describe KojacBaseController do

	#before(:each) do
	#	#@user = FactoryGirl.create(:user, ring: 3)
	#	#ApplicationController.any_instance.stub(:current_user).and_return(@user)
	#end

	it 'user read should return allowed fields' do
		stub_login_user(ring: USER_RING)
		@user2 = FactoryGirl.create(:user)
		read_op = {
			verb: 'READ',
			key: @user2.kojac_key
		}
		draw_routes do
			get ":controller/:action"
		end
		result = do_op(read_op)
		result.keys.sort.should == (User::PUBLIC_FIELDS).map(&:to_s).sort
	end

	it 'admin read should return more allowed fields' do
		stub_login_user(ring: ADMIN_RING)
		@user2 = FactoryGirl.create(:user)
		read_op = {
			verb: 'READ',
			key: @user2.kojac_key
		}
		draw_routes do
			get ":controller/:action"
		end
		result = do_op(read_op)
		result.keys.sort.should == (User::PUBLIC_FIELDS + User::PRIVATE_FIELDS + User::ADMIN_FIELDS + User::READ_ONLY_FIELDS).map(&:to_s).sort
	end

	it "user should not be able to update other's name" do
		user = stub_login_user(ring: USER_RING)
		user2 = FactoryGirl.create(:user)
		original_name = user2.last_name
		send_op = {
			verb: 'UPDATE',
			key: user2.kojac_key,
			value: {
				last_name: 'Smithy-Jones'
			}
		}
		draw_routes do
			get ":controller/:action"
		end
		expect { do_op(send_op) }.to raise_exception(Pundit::NotAuthorizedError)
		user2.reload
		user2.last_name.should == original_name
	end

	it 'user should be able to read own PRIVATE_FIELDS' do
		user = stub_login_user(ring: USER_RING)
		send_op = {
			verb: 'READ',
			key: user.kojac_key
		}
		draw_routes do
			get ":controller/:action"
		end
		result = do_op(send_op)
		result.keys.sort.should == (User::PUBLIC_FIELDS + User::PRIVATE_FIELDS).map(&:to_s).sort
	end


	it 'user should be able to update own name' do
		user = stub_login_user(ring: USER_RING)
		send_op = {
			verb: 'UPDATE',
			key: user.kojac_key,
			value: {
				last_name: 'Smithy-Jones'
			}
		}
		draw_routes do
			get ":controller/:action"
		end
		result = do_op(send_op)
		result['last_name'].should == send_op.g?('value.last_name')
		result.keys.sort.should == (User::PUBLIC_FIELDS + User::PRIVATE_FIELDS).map(&:to_s).sort
	end

	it 'admin user should be able to update user of same owner' do
		user = stub_login_user(ring: ADMIN_RING, owner_id: 1)
		user2 = FactoryGirl.create(:user, owner_id: 1)
		original_name = user2.last_name
		send_op = {
			verb: 'UPDATE',
			key: user2.kojac_key,
			value: {
				last_name: 'Smithy-Jones'
			}
		}
		draw_routes do
			get ":controller/:action"
		end
		result = do_op(send_op)
		result['last_name'].should == send_op.g?('value.last_name')
		user2.reload
		user2.last_name.should == send_op.g?('value.last_name')
		result.keys.sort.should == (User::PUBLIC_FIELDS + User::PRIVATE_FIELDS + User::ADMIN_FIELDS + User::READ_ONLY_FIELDS).map(&:to_s).sort
	end

	it 'admin user should not be able to update user of different owner' do
		user = stub_login_user(ring: ADMIN_RING, owner_id: 1)
		user2 = FactoryGirl.create(:user, owner_id: 2)
		original_name = user2.last_name
		send_op = {
			verb: 'UPDATE',
			key: user2.kojac_key,
			value: {
				last_name: 'Smithy-Jones'
			}
		}
		draw_routes do
			get ":controller/:action"
		end
		expect { do_op(send_op) }.to raise_exception(Pundit::NotAuthorizedError)
		user2.reload
		user2.last_name.should == original_name
	end

	it 'should read users' do
		@user = stub_login_user(ring: ADMIN_RING)
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
		draw_routes do
			get ":controller/:action"
		end
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

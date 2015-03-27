def setup_common_data
end

def stub_login_user(aValues=nil)
	aValues ||= {}
	aValues[:ring] ||= USER_RING
	user = FactoryGirl.create(:user,aValues)
	KojacBaseController.any_instance.stub(:current_user).and_return(user)
	user
end

def exec_op(read_op)
	content = {
		options: {},
		ops: [
			read_op
		]
	}
	request.accept = "application/json"
	post :receive, format: :json, kojac: content
	result = nil
	error = nil
	output = JSON.parse response.body
	if output['error']
		response.status.should >= 400
		output.g?('error.errors').should be_a Array
		output.g?('error.kind').should be
		output['error']['errors'].length.should >= 1
		error = output['error']
	else
		response.status.should == 200
		output['ops'].should be_a Array
		output['ops'].length.should >= 1
		op = output['ops'].first
		result = op['results'][op['result_key']]
	end
	[result,error]
end

# from http://openhood.com/rails/rails%203/2010/07/20/add-routes-at-runtime-rails-3/
def draw_routes(&block)
	begin
		app = Rails::Application.subclasses.first
	  _routes = app.routes
	  _routes.disable_clear_and_finalize = true
	  _routes.clear!
	  app.routes_reloader.paths.each{ |path| load(path) }
	  _routes.draw(&block)
	  ActiveSupport.on_load(:action_controller) { _routes.finalize! }
	ensure
	  _routes.disable_clear_and_finalize = false
	end
end

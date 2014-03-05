describe("Error Handling (requires web server)", function() {

	beforeEach(function () {
	});

	it("handles not found", function() {
		var App = {};
		App.cache = new Kojac.Cache();
		App.kojac = new Kojac.Core({
			cache: App.cache,
			remoteProvider: new Kojac.RemoteProvider({
				serverPath: '/sdfhjdfsdfhsjkhjdfskhjdfsjhkdfsdsf',
				timeout: 2000
			})
		});
		var op;
		var req;
		runs(function() {
			req = App.kojac.readRequest(['order_item']).done(function(aKR){
				console.log(aKR);
			}).fail(function(aKR){
				console.log(aKR);
			});
		});
		waitsFor(function() {
			return req.isResolved() || req.isRejected()
		}, "request done", 3000);
		runs(function() {
			var e = req.error;
			expect(e).toBeDefined();
			expect(e.format).toEqual('KojacError');
			expect(e.http_code).toEqual(404);
			expect(e.kind).toEqual('NotFound');
			expect(e.message).toBeTruthy();
			expect(e.debug_message).toBeTruthy();
			expect(e.xhr).toBeTruthy();
			expect(e.headers).toBeTruthy();
			expect(e.response).toBeTruthy();
		});
	});

});
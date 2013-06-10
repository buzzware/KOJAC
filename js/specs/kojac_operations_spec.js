describe("Kojac Operations", function() {

	beforeEach(function () {
		this.cache = Ember.Object.create();
		var factory = new Kojac.ObjectFactory();
		this.kojac = new Kojac.Core({
			cache: this.cache,
			remoteProvider: new Kojac.RemoteProvider({useMockFileValues: true, mockFilePath: 'mockjson/'}),
			objectFactory: factory
		});
	});

	it("try reading cur_super,cur_super_product", function() {
		var op;
		var req;
		runs(function() {
			req = this.kojac.read('cur_super').read('cur_super_product').read('cur_super__50');
			expect(req).toBeDefined('ops');
			expect(req).toBeDefined('options');
			expect(req.ops.length).toEqual(3);
			op = req.ops[0];
			expect(op.verb).toEqual('READ');
			expect(op.key).toEqual('cur_super');
			expect(op.result_key).toEqual(op.key);
			expect(op.results).toEqual({});
			op = req.ops[1];
			expect(op.verb).toEqual('READ');
			expect(op.key).toEqual('cur_super_product');
			expect(op.result_key).toEqual(op.key);
			expect(op.results).toEqual({});
			op = req.ops[2];
			expect(op.verb).toEqual('READ');
			expect(op.key).toEqual('cur_super__50');
			expect(op.result_key).toEqual(op.key);
			expect(op.results).toEqual({});
		});
	});
});




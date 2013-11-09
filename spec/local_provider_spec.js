describe("LocalStorageRemoteProvider", function() {

	var Waiter = Kojac.Model.extend({
		id: Int,
		name: String,
		phone: String,
		gender: String,   // M or F
		option: String,
		queued: Number,
		smsSent: false,
		completed: false,
		created_at: String,
		sendingSms: false
	});

	beforeEach(function () {
		$.jStorage.flush();
		this.cache = {};

		var factory = new Kojac.ObjectFactory();
		factory.register([
			[/^waiters(__|$)/,Waiter]
		]);
		this.kojac = new Kojac.Core({
			cache: this.cache,
			remoteProvider: new Kojac.LocalStorageRemoteProvider(),
			objectFactory: factory
		});
	});

	it("try create and then read item", function() {
		var op;
		var req;
		var newKey;
		var createValues = {
			name: 'John',
			phone: '0412 123456'
		};
		runs(function() {
			var waiter = new Waiter(createValues);
			req = this.kojac.createRequest({waiters: waiter});
		});
		waitsFor(function() { return req.isResolved() }, "request done", 3000);
		runs(function() {
			expect(req.ops).toBeDefined();
			expect(req.options).toBeDefined();
			expect(req.ops.length).toEqual(1);
			op = req.ops[0];
			expect(op.verb).toEqual('CREATE');
			expect(op.key).toEqual('waiters');
			newKey = op.result_key;
			expect(op.result_key).not.toEqual(op.key);
			var parts = keySplit(op.result_key);
			expect(parts[0]).toEqual('waiters');
			var id = _.toInt(parts[1]);
			expect(id).toBeGreaterThan(Math.pow(2,32));
			expect(id).toBeLessThan(Math.pow(2,52));
			expect(op.result.id).toEqual(id);
			expect(op.results).not.toEqual({});
			expect(op.result instanceof Waiter).toBeTruthy();

			req = this.kojac.readRequest(newKey);
		});
		waitsFor(function() { return req.isResolved() }, "request done", 3000);
		runs(function() {
			op = req.op;
			expect(op.result_key).toEqual(newKey);
			expect(op.result.name).toEqual(createValues.name);
			expect(op.result.phone).toEqual(createValues.phone);
			expect(op.result instanceof Waiter).toBeTruthy();
		});
	});

	it("try create and then read collection", function() {
		var op;
		var req;
		var newKey;
		var createValues = {
			name: 'John',
			phone: '0412 123456'
		};
		runs(function() {
			var waiter = new Waiter(createValues);
			req = this.kojac.createRequest({waiters: waiter});
		});
		waitsFor(function() { return req.isResolved() }, "request done", 3000);
		runs(function() {
			req = this.kojac.readRequest('waiters');
		});
		waitsFor(function() { return req.isResolved() }, "request done", 3000);
		runs(function() {
			op = req.op;
			expect(op.result_key).toEqual('waiters');
			expect(op.result instanceof Array).toBeTruthy();
			expect(op.result.length).toEqual(1);
			expect(_.keys(op.results).length).toBe(2);
			expect(op.results[op.result_key]).toBe(op.result);
			var id = op.result[0];
			var key = keyJoin('waiters',id);
			var waiter = op.results[key];
			expect(waiter).toBeDefined();
			expect(waiter.id).toEqual(id);

			expect(waiter.name).toEqual(createValues.name);
			expect(waiter.phone).toEqual(createValues.phone);
			expect(waiter instanceof Waiter).toBeTruthy();
		});
	});

	it("create, update then read item", function() {
		var op;
		var req;
		var newKey;
		var createValues = {
			name: 'Sam',
			phone: '0333 777777'
		};
		var updateValues = {
			phone: '0444 444444'
		};
		var combinedValues = _.extend({},createValues,updateValues);
		runs(function() {
			var waiter = new Waiter(createValues);
			req = this.kojac.createRequest({waiters: waiter});
		});
		waitsFor(function() { return req.isResolved() }, "request done", 3000);
		runs(function() {
			newKey = req.op.result_key;
			req = this.kojac.updateRequest([newKey,updateValues]);
		});
		waitsFor(function() { return req.isResolved() }, "request done", 3000);
		runs(function() {
			op = req.op;
			expect(op.result_key).toEqual(newKey);
			expect(op.result.name).toEqual(combinedValues.name);
			expect(op.result.phone).toEqual(combinedValues.phone);
			expect(op.result instanceof Waiter).toBeTruthy();
			req = this.kojac.readRequest(newKey);
		});
		waitsFor(function() { return req.isResolved() }, "request done", 3000);
		runs(function() {
			op = req.op;
			expect(op.result_key).toEqual(newKey);
			expect(op.result.name).toEqual(combinedValues.name);
			expect(op.result.phone).toEqual(combinedValues.phone);
			expect(op.result instanceof Waiter).toBeTruthy();
		})
	});

	it("create and then destroy item", function() {
		var op;
		var req;
		var newKey;
		var createValues = {
			name: 'John',
			phone: '0412 123456'
		};
		runs(function() {
			var waiter = new Waiter(createValues);
			req = this.kojac.createRequest({waiters: waiter});
		});
		waitsFor(function() { return req.isResolved() }, "request done", 3000);
		runs(function() {
			newKey = req.op.result_key;
			expect(this.kojac.cache[newKey]).toBeDefined();
			req = this.kojac.destroyRequest(newKey);
		});
		waitsFor(function() { return req.isResolved() }, "request done", 3000);
		runs(function() {
			expect(this.kojac.cache[newKey]).toBeUndefined();
			req = this.kojac.readRequest(newKey);
		});
		waitsFor(function() { return req.isResolved() }, "request done", 3000);
		runs(function() {
			op = req.op;
			expect(op.result_key).toEqual(newKey);
			expect(this.kojac.cache[newKey]).toBeUndefined();
		});
	});

});




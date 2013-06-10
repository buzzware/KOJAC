describe("Kojac Mock", function() {

	var OrderItem = Kojac.Object.extend({
		id: Int,
		customer_id: Int,
		product_id: Int
	});

	var Product = Kojac.Object.extend({

	});
		
	beforeEach(function () {
		this.cache = new Kojac.Object();
		var factory = new Kojac.ObjectFactory();
		factory.register([
			[/^order_item(__|$)/,OrderItem],
			[/^product(__|$)/,Product]
		]);
		this.kojac = new Kojac.Core({
			cache: this.cache,
			remoteProvider: new Kojac.RemoteProvider({useMockFileValues: true, mockFilePath: 'mockjson/'}),
			objectFactory: factory
		});
	});

	it("try reading order_item,product", function() {
		var op;
		var req;
		runs(function() {
			req = this.kojac.readRequest(['order_item','product','order_item__50']);
			expect(req).toBeDefined('ops');
			expect(req).toBeDefined('options');
			expect(req.ops.length).toEqual(3);
			op = req.ops[0];
			expect(op.verb).toEqual('READ');
			expect(op.key).toEqual('order_item');
			expect(op.result_key).toEqual(op.key);
			expect(op.results).toEqual({});
			op = req.ops[1];
			expect(op.verb).toEqual('READ');
			expect(op.key).toEqual('product');
			expect(op.result_key).toEqual(op.key);
			expect(op.results).toEqual({});
			op = req.ops[2];
			expect(op.verb).toEqual('READ');
			expect(op.key).toEqual('order_item__50');
			expect(op.result_key).toEqual(op.key);
			expect(op.results).toEqual({});
		});
		waitsFor(function() {
			return req.isResolved()
		}, "request done", 3000);
		runs(function() {
			expect(req.ops).toBeDefined();
			op = req.ops[0];
			expect(op.verb).toEqual('READ');
			expect(op.key).toEqual('order_item');
			expect(op.result_key).toEqual(op.key);
			expect(typeof(op.results)).toBe('object');
			expect(op.results.order_item).toEqual([49,50,51]);
			//expect(Ember.typeOf(op.results.order_item__49)).toBe('instance');
			expect(op.results.order_item__49.constructor).toBe(OrderItem);
			expect(op.results.order_item__49.id).toEqual(49);
			expect(op.results.order_item__49.accountRef).toEqual("000049X");
			expect(op.results.order_item__49.productId).toEqual(3);
			op = req.ops[1];
			expect(op.verb).toEqual('READ');
			expect(op.key).toEqual('product');
			expect(op.result_key).toEqual(op.key);
			expect(typeof(op.results)).toBe('object');
			expect(op.results.product).toEqual([3,4,5]);
			//expect(Ember.typeOf(op.results.product__3)).toBe('instance');
			expect(op.results.product__3.constructor).toBe(Product);
			expect(op.results.product__3.name).toEqual("Product 3");
			expect(op.results.product__3.provider).toEqual("AJAX Pty Ltd");
			op = req.ops[2];
			expect(op.verb).toEqual('READ');
			expect(op.key).toEqual('order_item__50');
			expect(op.result_key).toEqual(op.key);
			//expect(Ember.typeOf(op.results.order_item__50)).toBe('instance');
			expect(op.results.order_item__50.constructor).toBe(OrderItem);
			expect(op.results.order_item__50.accountRef).toEqual("000050X");
			expect(op.results.order_item__50.memberTypeId).toEqual("CDB");
			expect(op.results.order_item__50.drawings).toEqual(1234.50);

			expect(this.cache.order_item__49).toBeDefined();
			expect(this.cache.order_item__49).toBe(req.ops[0].results.order_item__49);
			expect(this.cache.product__3).toBeDefined();
			expect(this.cache.product__3).toBe(req.ops[1].results.product__3);
		});
	});

	it("try creating", function() {
		var op;
		var req;
		this.kojac.remoteProvider.mockWriteOperationHandler = function(aOp) {
			op.result_key = 'order_item__54';
			op.results = {
				order_item__54: op.value
			};
		};
		runs(function() {
			req = this.kojac.createRequest([{order_item:{name: 'Fred'}}]);
			expect(req).toBeDefined('ops');
			expect(req).toBeDefined('options');
			expect(req.ops.length).toEqual(1);
			op = req.ops[0];
			expect(op.verb).toEqual('CREATE');
			expect(op.key).toEqual('order_item');
			expect(op.value).toEqual({name: 'Fred'});
			expect(op.result_key).toEqual('order_item__54');
			expect(op.results).toBeUndefined();
		});
		waitsFor(function() { return req.isResolved(); }, "request done", 3000);
		runs(function() {
			expect(req.ops).toBeDefined();
			op = req.ops[0];
			expect(op.verb).toEqual('CREATE');
			expect(op.key).toEqual('order_item');
			expect(op.result_key).toEqual('order_item__54');
			expect(typeof(op.results)).toBe('object');
			expect(op.results.order_item).toBeUndefined();
			//expect(Ember.typeOf(op.results.order_item__54)).toBe('instance');
			expect(op.results.order_item__54.constructor).toBe(OrderItem);
			expect(op.results.order_item__54.name).toEqual("Fred");

			expect(this.cache.order_item__54).toBeDefined();
			expect(this.cache.order_item__54).toBe(op.results.order_item__54);
		});
	});

	it("try updating", function() {
		var op;
		var req;
		this.kojac.remoteProvider.mockWriteOperationHandler = function(aOp) {
			op.result_key = op.key;
			op.results = {
				order_item__54: op.value
			};
		};
		runs(function() {
			req = this.kojac.updateRequest({order_item__54: {name: 'John'}});
			expect(req).toBeDefined('ops');
			expect(req).toBeDefined('options');
			expect(req.ops.length).toEqual(1);
			op = req.ops[0];
			expect(op.verb).toEqual('UPDATE');
			expect(op.key).toEqual('order_item__54');
			expect(op.value).toEqual({name: 'John'});
			expect(op.result_key).toEqual(op.key);
			expect(op.results).toBeUndefined();
		});
		waitsFor(function() { return req.isResolved(); }, "request done", 3000);
		runs(function() {
			expect(req.ops).toBeDefined();
			op = req.ops[0];
			expect(op.result_key).toEqual(op.key);
			expect(typeof(op.results)).toBe('object');
			expect(op.results.order_item).toBeUndefined();
			//expect(Ember.typeOf(op.results.order_item__54)).toBe('instance');
			expect(op.results.order_item__54.constructor).toBe(OrderItem);
			expect(op.results.order_item__54.name).toEqual("John");

			expect(this.cache.order_item__54).toBeDefined();
			expect(this.cache.order_item__54).toBe(op.results.order_item__54);
		});
	});

	it("try destroying", function() {
		var op;
		var req;
		this.kojac.remoteProvider.mockWriteOperationHandler = function(aOp) {
			op.result_key = op.key;
			op.results = {
				order_item__54: undefined
			};
		};
		runs(function() {
			req = this.kojac.destroyRequest(['order_item__54']);
			expect(req).toBeDefined('ops');
			expect(req).toBeDefined('options');
			expect(req.ops.length).toEqual(1);
			op = req.ops[0];
			expect(op.verb).toEqual('DESTROY');
			expect(op.key).toEqual('order_item__54');
			expect(op.value).toBeUndefined();
			expect(op.result_key).toEqual(op.key);
			expect(op.results).toBeUndefined();
		});
		waitsFor(function() { return req.isResolved(); }, "request done", 3000);
		runs(function() {
			expect(req.ops).toBeDefined();
			op = req.ops[0];
			expect(op.result_key).toEqual(op.key);
			expect(typeof(op.results)).toBe('object');
			expect(op.results.order_item__54).toBeUndefined();
			expect(this.cache.order_item__54).toBeUndefined();
		});
	});

	it("try executing", function() {
		var op;
		var req;
		this.kojac.remoteProvider.mockReadOperationHandler = function(aOp) {
			op.result_key = op.key;
			op.results = {
				results: [1,2,3]
			};
		};
		runs(function() {
			req = this.kojac.executeRequest('results',{a: 1,b:2},{cacheResults: true});
			expect(req).toBeDefined('ops');
			expect(req).toBeDefined('options');
			expect(req.ops.length).toEqual(1);
			op = req.ops[0];
			expect(op.verb).toEqual('EXECUTE');
			expect(op.key).toEqual('results');
			expect(op.value).toEqual({a: 1,b:2});
			expect(op.result_key).toEqual(op.key);
			expect(op.results).toBeUndefined();
		});
		waitsFor(function() { return req.isResolved(); }, "request done", 3000);
		runs(function() {
			expect(req.ops).toBeDefined();
			op = req.ops[0];
			expect(op.result_key).toEqual(op.key);
			expect(typeof(op.results)).toBe('object');
			expect(op.results.results).toEqual([1,2,3]);
			expect(this.cache.results).toEqual([1,2,3]);
		});
	});

});


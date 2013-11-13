describe("Operation include spec", function() {

	var App = {};
	
	var OrderItem = Kojac.Object.extend({
		id: Int,
		customer_id: Int,
		product_id: Int
	});

	var Product = Kojac.Object.extend({

	});
		
	beforeEach(function () {
		App.cache = new Kojac.Cache();
		var factory = new Kojac.ObjectFactory();
		factory.register([
			[/^order_item(__|$)/,OrderItem],
			[/^product(__|$)/,Product]
		]);
		App.kojac = new Kojac.Core({
			cache: App.cache,
			remoteProvider: new Kojac.RemoteProvider(),
			objectFactory: factory
		});
	});

	it("try reading order_item,product", function() {
		var op;
		var req;
		App.kojac.remoteProvider.mockReadOperationHandler = function(aOp) {
			op.result_key = 'order_item__50';
			op.results = {
				order_item__50: {
					id: 50,
					accountRef: "000049X",
					productId: 3
				},
				product__3: {
					id: 3,
					name: "Bubble"
				}
			};
		};
		runs(function() {
			req = App.kojac.readRequest('order_item__50',{include: 'product'});
			expect(req).toBeDefined('ops');
			expect(req.options).toEqual({});
			expect(req.ops.length).toEqual(1);
			op = req.ops[0];
			expect(op.options).toEqual({include: 'product', cacheResults: true, manufacture : true});
			expect(op.verb).toEqual('READ');
			expect(op.key).toEqual('order_item__50');
			expect(op.result_key).toEqual(op.key);
		});
		waitsFor(function() {
			return req.isResolved()
		}, "request done", 3000);
		runs(function() {
			op = req.ops[0];
			expect(op.result_key).toEqual(op.key);
			expect(typeof(op.results)).toBe('object');
			expect(op.results.order_item__50).toBeDefined();
			expect(op.results.order_item__50.constructor).toBe(OrderItem);
			expect(op.results.order_item__50.id).toEqual(50);
			expect(op.results.order_item__50.accountRef).toEqual("000049X");
			expect(op.results.order_item__50.productId).toEqual(3);

			expect(op.results.product__3).toBeDefined();
			expect(op.results.product__3.constructor).toBe(Product);
			expect(op.results.product__3.id).toEqual(3);
			expect(op.results.product__3.name).toEqual("Bubble");
		});
	});
});


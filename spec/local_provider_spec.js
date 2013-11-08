describe("LocalStorageRemoteProvider", function() {

	// returns an id above the normal 32 bit range of rails but within the range of Javascript
	Kojac.Utils.createId = function () {
		return _.randomIntRange(4294967296,4503599627370496); // 2**32 to 2**52 see http://stackoverflow.com/questions/9389315/cross-browser-javascript-number-precision
	};

	Kojac.LocalStorageRemoteProvider = Kojac.Object.extend({
		operationsToJson: function(aOps) {
			var result = [];
			for (var i=0;i<aOps.length;i++) {
				var op = aOps[i];
				var jsonOp = {
					verb: op.verb,
					key: op.key
				};
				if ((op.verb==='CREATE') || (op.verb==='UPDATE') || (op.verb==='EXECUTE')) {
					jsonOp.value = Kojac.Utils.toJsono(op.value,op.options);
				}
				var options = op.options && _.omit(op.options,['cacheResults','preferCache']);
				if (options && !_.isEmpty(options))
					jsonOp.options = options;   // omit local keys
				jsonOp.params = op.params;
				result.push(jsonOp);
			}
			return result
		},

		handleAjaxRequest: function(aRequest) {
			var aRequestOp;
			if (!aRequest.ops.length)
				return;
			var ops = this.operationsToJson(aRequest.ops);
			var op_output;
			var v,op,id,key,value,parts,results,result_key;
			for (var i=0;i<ops.length;i++) {
				op = ops[i];
				aRequestOp = aRequest.ops[i];
				if (op.verb=='CREATE') {
					id = Kojac.Utils.createId();
					key = keyJoin(op.key,id);
					result_key = (op.result_key || key);
					value = _.clone(op.value,true,true);
					value.id = id;

					$.jStorage.set(key,value);
					results = {};
					results[result_key] = value;
					op_output = {
						key: op.key,
					  verb: op.verb,
					  result_key: result_key,
					  results: results
					};
				} else if (op.verb=='READ') {
					result_key = (op.result_key || op.key);
					results = {};
					parts = keySplit(op.key);
					if (parts[1]) { // item
						value = $.jStorage.get(op.key,Boolean);
						if (value===Boolean)
							value = undefined;
						results[result_key] = value;
					} else {  // collection
						var keys = $.jStorage.index();
						var ids = [];
						_.each(keys,function(k){
							parts = keySplit(k);
							id = parts[1];
							if (parts[0]!=op.key || !id)
								return;
							ids.push(id);
							v = $.jStorage.get(k,Boolean);
							if (value===Boolean)
								value = undefined;
							results[k] = v;
						});
						results[result_key] = ids;
					}
					op_output = {
						key: op.key,
					  verb: op.verb,
					  result_key: result_key,
					  results: results
					};
				} else if (op.verb=='UPDATE') {
					value = $.jStorage.get(op.key,Boolean);
					if (value===Boolean)
						value = undefined;
					result_key = (op.result_key || op.key);
					if (_.isObjectStrict(value))
						_.extend(value,op.value);
					else
						value = op.value;
					$.jStorage.set(op.key,value);
					results = {};
					results[result_key] = value;
					op_output = {
						key: op.key,
					  verb: op.verb,
					  result_key: result_key,
					  results: results
					};
				} else if (op.verb=='DESTROY') {
					$.jStorage.deleteKey(op.key);
					result_key = (op.result_key || op.key);
					results = {};
					//results[result_key] = undefined;
					op_output = {
						key: op.key,
					  verb: op.verb,
					  result_key: result_key,
					  results: results
					};
				} else {
					throw "verb not implemented";
				}
				aRequestOp.receiveResult(op_output);
				aRequestOp.fromCache = false;
				aRequestOp.performed = true;
			}
			console.log('end');
		}
	});

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




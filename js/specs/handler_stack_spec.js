describe("HandlerStack", function() {

	it("simple add", function() {
		var hs = new HandlerStack();
		var context = {text: 'A'};

		hs.add(function(aContext) {
			context.text += 'B';
		});
		hs.add(function(aContext) {
			context.text += 'C';
		});
		runs(function() {
			hs.execute(context);
		});
		waitsFor(function() { return context.isResolved(); }, "request done", 3000);
		runs(function() {
			expect(context.text).toBe('ABC');
		});
	});

	it("add, push, then and done", function() {
		var hs = new HandlerStack();
		var context = {text: 'A'};

		hs.add(function(aContext) {
			context.text += 'B';
		});
		hs.add(function(aContext) {
			context.text += 'C';
		});
		hs.push(function(aContext) {
			context.text += 'X';
		});
		runs(function() {
			hs.execute(context);
			context.then(function(aContext){
				context.text += 'W';
			});
			context.done(function(aContext){
				context.text += 'Z';
			});
		});
		waitsFor(function() { return context.isResolved(); }, "request done", 3000);
		runs(function() {
			expect(context.text).toBe('AXBCWZ');
		});
	});

	it("error handling - stop processing handlers and set context.error and context.isRejected and call fail handler", function() {
		var hs = new HandlerStack();
		var context = {text: 'A'};

		hs.add(function(aContext) {
			context.text += 'B';
		});
		hs.add(function(aContext) {
			throw new Error();
		});
		hs.add(function(aContext) {
			context.text += 'X';
		});
		hs.execute(context);
		context.then(function(aContext){
			context.text += 'W';
		});
		context.done(function(aContext){
			context.text += 'Z';
		});
		context.fail(function(aContext){
			context.text += 'F';
		});
		waitsFor(function() {
			return context.isRejected();
		}, "rejected", 3000);
		runs(function() {
			expect(context.text).toBe('ABF');
			expect(context.error).toBeDefined();
			expect(typeof(context.error)).toBe('object');
		});
	});

	it("reset and recall", function() {
		var hs = new HandlerStack();
		var context = {text: 'A'};

		hs.add(function(aContext) {
			context.text += 'B';
		});
		runs(function() {
			hs.execute(context);
			context.then(function(aContext){
				context.text += 'W';
			});
			context.done(function(aContext){
				context.text += 'Z';
			});
		});
		waitsFor(function() { return context.isResolved(); }, "resolved", 3000);
		runs(function() {
			expect(context.text).toBe('ABWZ');
			expect(context.error).toBeUndefined();
			hs.reset();
		});

		runs(function() {
			context = {text: 'G'};
			hs.execute(context);
			context.then(function(aContext){
				context.text += 'W';
			});
			context.done(function(aContext){
				context.text += 'Z';
			});
		});
		waitsFor(function() { return context.isResolved(); }, "resolved", 3000);
		runs(function() {
			expect(context.text).toBe('GBWZ');
			expect(context.error).toBeUndefined();
		});

	});

	it("handler on an object", function() {
		var hs = new HandlerStack();
		var context = {text: 'A'};
		var TestClass = function() {
			this.text = 'B';
			this.go = function(aContext) {
				aContext.text += this.text;
			};
		};
		var testClass = new TestClass();
		hs.add(testClass.go,null,testClass); // note: using ability to specify this as third parameter
		runs(function() {
			hs.execute(context);
		});
		waitsFor(function() { return context.isResolved(); }, "resolved", 3000);
		runs(function() {
	 	  expect(context.text).toBe('AB');
		});
	});
});
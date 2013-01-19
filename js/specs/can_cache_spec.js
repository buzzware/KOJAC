describe("Kojac.CanCache Specs", function() {

	beforeEach(function () {
		this.cache = new Kojac.CanCache({});
		var factory = new Kojac.CanObjectFactory({});
		this.kojac = new Kojac.Core({
			cache: this.cache,
			remoteProvider: new Kojac.RemoteProvider({useMockFileValues: true,mockFilePath: '/em/dev/mockjson/'}),
			objectFactory: factory
		});
	});

	var testValues = {
		astring: 'some string',
		anumber: 12345,
		aboolean: true,
		adate: Date.now(),
		aobject: {name: 'A little object'},
		aarray: [1,2,3,4,5]
	};

	it("should return the same type as was stored", function() {
		var cache = this.cache;
		_.each(['astring','anumber','aboolean','adate'],function(p) {
			cache.attr(p,testValues[p]);
			expect(cache.attr(p)).toEqual(testValues[p]);
		});
		var p = 'aobject';
		cache.attr(p,testValues[p]);
		var fromCache = cache.attr(p);
		expect(fromCache.attr()).toEqual(testValues.aobject);
		expect(fromCache.name).toEqual(testValues.aobject.name);

		p = 'aarray';
		cache.attr(p,testValues[p]);
		fromCache = cache.attr(p);
		expect(fromCache.attr()).toEqual(testValues[p]);
		for (var i=0;i<testValues[p].length;i++)
			expect(fromCache[i]).toEqual(testValues[p][i]);
	});

	it("Expose bug in can.Observe when setting attribute with another can.Observe", function() {
		var cache = new can.Observe({});
		var cs1 = new can.Observe({});
		var cont1 = {cur_super_43: cs1};

		var cs2 = new can.Observe({});
		var cont2 = {cur_super_43: cs2};

		cache.attr(cont1);
		expect(cache.attr('cur_super_43')).toEqual(cs1);
		cache.attr(cont2);
		expect(cache.attr('cur_super_43')).toEqual(cs2);
	});

//	keys = [...]
//	kojac.cacheHasKeys(keys)
//	kojac.cacheHasKeys(keys)
//	kojac.cacheValues(keys)

	it("Kojac.Utils.interpretKeys", function() {
		expect(Kojac.Utils.interpretKeys(undefined)).toEqual([]);
		expect(Kojac.Utils.interpretKeys(null)).toEqual([]);
		expect(Kojac.Utils.interpretKeys('a')).toEqual(['a']);
		expect(Kojac.Utils.interpretKeys('a,b,c')).toEqual(['a','b','c']);
		expect(Kojac.Utils.interpretKeys(['a','b','c'])).toEqual(['a','b','c']);
	});

	it("kojac.cacheHasKeys", function() {
		expect(this.kojac.cacheHasKeys(['a','b','c'])).toBe(false);
		this.cache.a = 1;
		expect(this.kojac.cacheHasKeys(['a'])).toBe(true);
		expect(this.kojac.cacheHasKeys(['a','b','c'])).toBe(false);
		this.cache.b = null;
		this.cache.c = 'hello';
		expect(this.kojac.cacheHasKeys(['a','b','c'])).toBe(true);
	});

	it("kojac.cacheValues", function() {
		expect(this.kojac.cacheValues(['a','b','c'])).toEqual([undefined,undefined,undefined]);
		this.cache.a = 1;
		this.cache.b = null;
		this.cache.c = 'hello';
		expect(this.kojac.cacheValues(['a','b','c'])).toEqual([1,null,'hello']);
	});

});

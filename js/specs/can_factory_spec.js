describe("CanJs Factory spec", function() {

	var CurSuper = Kojac.Model.extend({
		id: Int,
		owner: String,
		accountRef: String,
		productId: Int
	});

	it("create Can Object from plain object", function() {
		var factory = new Kojac.CanObjectFactory();
		factory.register([
			[/^cur_super(__|$)/,CurSuper]
		]);
		var source = {
			id: 51,
			name: 'Fred',
			width: 100,
			enabled: true,
			details: {
				message: 'some message'
			},
			nothing: null
		};

		var canObject = factory.manufacture(source,'cur_super__51');
		expect(canObject).toBeDefined();
		expect(canObject.constructor).toBe(CurSuper);
		expect(canObject.id).toBe(source.id);
		expect(canObject.name).toBe(source.name);
		expect(canObject.enabled).toBe(source.enabled);
		expect(canObject.details).toEqual(source.details);
		expect(canObject.nothing).toBe(source.nothing);
		expect(canObject.attr('id')).toBe(source.id);
		expect(canObject.name).toBe(source.name);
		expect(canObject.enabled).toBe(source.enabled);
		expect(canObject.details).toEqual(source.details);
		expect(canObject.nothing).toBe(source.nothing);
	});

	it("create Can Objects from plain objects", function() {
		var factory = new Kojac.CanObjectFactory({});
		factory.register([
			[/^cur_super(__|$)/,CurSuper]
		]);
		var source = [
			{
				id: 51,
				name: 'Fred',
				width: 100,
				enabled: true,
				details: {
					message: 'some message'
				},
				nothing: null
			},
			{
				id: 52,
				name: 'John',
				width: 102,
				enabled: false,
				details: {
					message: 'another message'
				},
				nothing: null
			}
		];

		var canObjects = factory.manufacture(source,'cur_super');
		var canObject = canObjects[0];
		expect(canObject).toBeDefined();
		expect(canObject.constructor).toBe(CurSuper);
		expect(canObject.id).toBe(source[0].id);
		expect(canObject.name).toBe(source[0].name);
		expect(canObject.enabled).toBe(source[0].enabled);
		expect(canObject.details).toEqual(source[0].details);
		expect(canObject.nothing).toBe(source[0].nothing);
		canObject = canObjects[1];
		expect(canObject).toBeDefined();
		expect(canObject.constructor).toBe(CurSuper);
		expect(canObject.id).toBe(source[1].id);
		expect(canObject.name).toBe(source[1].name);
		expect(canObject.enabled).toBe(source[1].enabled);
		expect(canObject.details).toEqual(source[1].details);
		expect(canObject.nothing).toBe(source[1].nothing);
	});

	var exampleDefA = {
		astring: String,
		anumber: Number,
		aboolean: Boolean,
		aint: Int,
		aobject: Object,
		__allowDynamic: false
	};

	var exampleSourceA = {
		astring: 'hello',
		anumber: 1,
		aboolean: true,
		aint: 3,
		aobject: {name: 'Fred'}
	};

	it("Try defining properties with classes and then readTypedProperties without conversion required", function() {
		expect(exampleDefA.astring===String);
		expect(exampleDefA.anumber===Number);
		expect(exampleDefA.aboolean===Boolean);
		expect(exampleDefA.aint===Int);
		expect(exampleDefA.aobject===Object);

		expect(exampleDefA.aobject!==Int);
		expect(exampleDefA.aobject!==String);
		expect(exampleDefA.aobject!==Number);

		expect(exampleDefA.aint!==String);
		expect(exampleDefA.aint!==Object);

		var obj = {};
		obj = Kojac.readTypedProperties(obj,exampleSourceA,exampleDefA);
		expect(obj).toEqual(exampleSourceA);
	});

	var exampleSourceB = {
		astring: 111,
		anumber: "123",
		aboolean: 1,
		aint: 5.6,
		aobject: [2,3,4]
	};

	it("Try readTypedProperties needing conversion", function() {
		var obj = Kojac.readTypedProperties({},exampleSourceB,exampleDefA);
		expect(obj).toEqual({
			astring: "111",
			anumber: 123.0,
			aboolean: true,
			aint: 6,
			aobject: null
		});
	});

});


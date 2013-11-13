describe("Ember Factory", function() {

	 var OrderItem = Ember.Object.extend({});
//		id: Int,
//		customer_id: Int,
//		product_id: Int
//	});

	var Product = Ember.Object.extend({

	});

	it("create Ember.Object from plain object", function() {
		var factory = new Kojac.EmberObjectFactory();
		factory.register([
			[/^order_item(__|$)/,OrderItem],
			[/^product(__|$)/,Product]
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

		var emberObject = factory.manufacture(source,'order_item__51');
		expect(emberObject).toBeDefined();
		expect(emberObject.constructor).toBe(OrderItem);
		expect(emberObject.id).toBe(source.id);
		expect(emberObject.name).toBe(source.name);
		expect(emberObject.enabled).toBe(source.enabled);
		expect(emberObject.details).toBe(source.details);
		expect(emberObject.nothing).toBe(source.nothing);
		expect(emberObject.get('id')).toBe(source.id);
		expect(emberObject.get('name')).toBe(source.name);
		expect(emberObject.get('enabled')).toBe(source.enabled);
		expect(emberObject.get('details')).toBe(source.details);
		expect(emberObject.get('nothing')).toBe(source.nothing);
	});

	it("create Ember.Objects from plain objects", function() {
		var factory = new Kojac.EmberObjectFactory();
		factory.register([
			[/^order_item(__|$)/,OrderItem],
			[/^product(__|$)/,Product]
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

		var emberObjects = factory.emberObjectFactoryArray(source,'order_item');
		var emberObject = emberObjects[0];
		expect(emberObject).toBeDefined();
		expect(emberObject.constructor).toBe(OrderItem);
		expect(emberObject.id).toBe(source[0].id);
		expect(emberObject.name).toBe(source[0].name);
		expect(emberObject.enabled).toBe(source[0].enabled);
		expect(emberObject.details).toBe(source[0].details);
		expect(emberObject.nothing).toBe(source[0].nothing);
		emberObject = emberObjects[1];
		expect(emberObject).toBeDefined();
		expect(emberObject.constructor).toBe(OrderItem);
		expect(emberObject.id).toBe(source[1].id);
		expect(emberObject.name).toBe(source[1].name);
		expect(emberObject.enabled).toBe(source[1].enabled);
		expect(emberObject.details).toBe(source[1].details);
		expect(emberObject.nothing).toBe(source[1].nothing);
	});

	// TYPE     declare null    declare default   null value
	// string:  String          'hello'           null
	// int:     Int             1                 null or NaN ?
	// float:   Number          0.9               null or NaN ?
	// boolean: Boolean         true              null
	// object:  Object          {blah: 67}        null
	//
	// Perhaps return null in all cases
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


describe("can_model_specs", function() {

	var CurSuper = Kojac.CanModel('CurSuper',{},{
		id: Int,
		accountRef: String,
		productId: Int,
		drawings: Number,
		holdings: Array,
		comments: Object
	});


	it("write, read and check with correct types", function() {
		var values = {
			id: 123,
			accountRef: 'XYZ',
			productId: 456,
			drawings: 3567.88,
			holdings: [{name: 'this'},{name: 'that'}],
			comments: {name: 'something else'}
		};
		var curSuper = new CurSuper(values);
		expect(curSuper.attr()).toEqual(values);
		expect(curSuper.serialize()).toEqual(values);
	});

	it("write incorrect types, then read and check with attr and serialize", function() {
		var incorrectValues = {
			id: 123.345,
			accountRef: 345345346,
			productId: '456',
			drawings: '3567.88',
			holdings: "something",
			comments: 'something else'
		};
		var correctValues = {
			id: 123,
			accountRef: '345345346',
			productId: 456,
			drawings: 3567.88,
			holdings: null,
			comments: null
		};
		var curSuper = new CurSuper(incorrectValues);
		expect(curSuper.attr()).toEqual(correctValues);
		_.extend(curSuper,incorrectValues);
		expect(curSuper.serialize()).toEqual(correctValues);
	});



	it("test if Observe methods are bound", function() {
		var TestOb = can.Observe('TestOb',{},{
			count: 0,
			inc: function() {
				this.count += 1;
			}
		});

		var testOb = new TestOb({});
		expect(testOb.count).toEqual(0);
		testOb.inc();
		expect(testOb.count).toEqual(1);
	});

	it("test if my Model methods are bound", function() {

		Kojac.TestModel = function(aName,aClass,aInstance) {
			return can.Observe(aName,aClass,aInstance);
		};

		var TestModel = Kojac.TestModel('TestModel',{
			attributes: {count: 'number'},
			defaults: {count: 0}
//			serialize : MODEL_FIELD_CONVERTERS, // these are only used when you call .serialize()
//			convert: MODEL_FIELD_CONVERTERS // these are only used when you set properties with attr
		},{
			inc: function() {
				this.count += 1;
			}
		});

		var testModel = new TestModel({});
		expect(testModel.count).toEqual(0);
		testModel.inc();
		expect(testModel.count).toEqual(1);
	});


	it("Can.JS defaults test", function() {
		var Zelda = can.Observe({
			defaults: {
				sword: 'Wooden Sword',
				shield: false,
				hearts: 3,
				rupees: 0
			}
		},{});

		var link = new Zelda({
			rupees: 255
		});

		expect(link.attr('sword')).toEqual('Wooden Sword');
		expect(link.attr('rupees')).toEqual(255);
	});


	it("Kojac.CanModel defaults and methods work", function() {
		console.log('before declare TestModel');
		var TestModel = Kojac.CanModel('TestModel',{},{
			count: 5,
			inc: function() {
				this.count += 1;
			}
		});

		console.log('before new TestModel');
		var testModel = new TestModel({});
		console.log('after new TestModel');
		expect(testModel.attr('count')).toBe(5);
		testModel.inc();
		expect(testModel.count).toEqual(6);
	});


});

describe("Kojac Model", function() {

	var TestModel = Kojac.Model.extend({
		name: String,
		count: 8
	});

	var TestModel2 = TestModel.extend({
		name: Boolean,
		color: 'red'
	});

	var TestModel3 = TestModel.extend({
		count: 0,
		inc: function() {
			this.count += 1;
		}
	});

	it("create model class and object", function() {
		expect(TestModel.__attributes).toEqual({name: String, count: Int});
		expect(TestModel._superClass).toBe(Kojac.Model);
		var testModel = new TestModel();
		expect(testModel instanceof TestModel).toBe(true);
		expect(testModel instanceof Kojac.Object).toBe(true);
		expect(testModel.name).toBeNull();
		expect(testModel.count).toBe(8);
		expect(testModel.toJSON).toBeDefined();
	});

	it("extend with override and additional attribute", function() {
		expect(TestModel2.__attributes).toEqual({name: Boolean, count: Int, color: String});
		expect(TestModel2._superClass).toBe(TestModel);
		var testModel2 = new TestModel2();
		expect(testModel2 instanceof TestModel2).toBe(true);
		expect(testModel2 instanceof Kojac.Object).toBe(true);
		expect(testModel2.name).toBeNull();
		expect(testModel2.count).toBe(8);
	});

	var CurSuper = Kojac.Model.extend({
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
	});


	it("test if Model methods are bound", function() {
		var testModel3 = new TestModel3();
		expect(testModel3.count).toEqual(0);
		testModel3.inc();
		expect(testModel3.count).toEqual(1);
	});

	it("defaults test", function() {
		var Zelda = Kojac.Model.extend({
			sword: 'Wooden Sword',
			shield: false,
			hearts: 3,
			rupees: 0
		});
		var link = new Zelda({
			rupees: 255
		});
		expect(link.attr('sword')).toEqual('Wooden Sword');
		expect(link.attr('rupees')).toEqual(255);
	});

	it("Kojac.Model defaults and methods work", function() {
		var MyTestModel = Kojac.Model.extend({
			count: 5,
			inc: function() {
				this.count += 1;
			}
		});
		console.log('before new MyTestModel');
		var testModel = new MyTestModel({});
		console.log('after new MyTestModel');
		expect(testModel.attr('count')).toBe(5);
		testModel.inc();
		expect(testModel.count).toEqual(6);
	});

});


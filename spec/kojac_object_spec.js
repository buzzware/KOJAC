describe("John Resigs JrClass", function() {

	it("JRs tests",function(){
		var Person = JrClass.extend({
//		  init: function(isDancing){
//		    this.dancing = isDancing;
//		  },
		  dance: function(){
		    return this.dancing;
		  }
		});
		var Ninja = Person.extend({
		  init: function(){
		    this._super({dancing: false});
		  },
		  dance: function(){
		    // Call the inherited version of dance()
		    return this._super();
		  },
		  swingSword: function(){
		    return true;
		  }
		});

		var p = new Person({dancing: true});
		expect(p.dance()).toBeTruthy();

		var n = new Ninja();
		expect(n.dance()).toBeFalsy();
		expect(n.swingSword()).toBeTruthy();

		// Should all be true
		expect(p instanceof Person).toBeTruthy();
		expect(p instanceof JrClass).toBeTruthy();
		expect(n instanceof Ninja).toBeTruthy();
		expect(n instanceof Person).toBeTruthy();
		expect(n instanceof JrClass).toBeTruthy();
	});

	it("create base class and object", function() {

		var Person = JrClass.extend({
			dancing: false
		});
		var Ninja = Person.extend({
			dancing: true
		});

		var p = new Person();
		expect(p.dancing).toBeFalsy();
		p = new Person({dancing: true});
		expect(p.dancing).toBeTruthy();

		var n = new Ninja();
		expect(n.dancing).toBeTruthy();
		n = new Ninja({dancing: false});
		expect(n.dancing).toBeFalsy();

	});

	it("test _super", function() {

		var Person = JrClass.extend({
//			init: function(aProperties){
//				this.dancing = isDancing;
//			},
			dance: function(){
				return this.dancing;
			}
		});
		var Ninja = Person.extend({
			init: function(){
				this._super({dancing: false});
			},
			dance: function(){
				// Call the inherited version of dance()
				return this._super();
			},
			swingSword: function(){
				return true;
			}
		});

		var p = new Person({dancing: true});
		expect(p.dance()).toBeTruthy();

		var n = new Ninja();
		expect(n.dance()).toBeFalsy();
		expect(n.swingSword()).toBeTruthy();

		// Should all be true
		expect(p instanceof Person).toBeTruthy();
		expect(p instanceof JrClass).toBeTruthy();
		expect(n instanceof Ninja).toBeTruthy();
		expect(n instanceof Person).toBeTruthy();
		expect(n instanceof JrClass).toBeTruthy();

	});

	it("JrClass descendant should clone objects and arrays when used as class default values when extending, but not when instantiating", function(){
		var OpDefObject = {};
		var Op = JrClass.extend({
			anObject: OpDefObject,
			anArray: [],
			aNumber: 5
		});
		var op1 = new Op();
		var op2 = new Op();
		expect(op1.aNumber).toBe(5);
		expect(op2.aNumber).toBe(5);
		op2.aNumber = 7;
		expect(op2.aNumber).toBe(7);

		expect(op1.anObject).not.toBe(OpDefObject);
		op1.anObject.something = "elephant";
		expect(op1.anObject).toEqual({something: "elephant"});
		expect(op2.anObject).not.toBe(OpDefObject);
		expect(op2.anObject).toEqual({});

		var instanceObject = {name: 'instanceObject'};
		var op3 = new Op({anObject: instanceObject});
		expect(op3.anObject).toBe(instanceObject);

		expect(op3.toJSON).toBeDefined();
	});

	it("JrClass should not clone objects or arrays when used as instance values", function(){
		var anObject = {};
		var anArray = [];
		var op = new JrClass({
			anObject: anObject,
			anArray: anArray,
			aNumber: 5
		});
		expect(op.aNumber).toBe(5);
		expect(op.anObject).toBe(anObject);
		expect(op.anArray).toBe(anArray);
		expect(op.toJSON).toBeDefined();
	});

	it("test if JrClass methods are bound", function() {
		var TestModel3 = JrClass.extend({
			count: 4,
			inc: function() {
				this.count += 1;
			}
		});
		var testModel3 = new TestModel3();
		expect(testModel3.count).toEqual(4);
		testModel3.inc();
		expect(testModel3.count).toEqual(5);

		var TestModel4 = TestModel3.extend({
			inc2: function() {
				this.count += 1;
			}
		});
		var testModel4 = new TestModel4();
		expect(testModel4.count).toEqual(4);
		testModel4.inc();
		expect(testModel4.count).toEqual(5);
		testModel4.inc2();
		expect(testModel4.count).toEqual(6);

		var testModel42 = new TestModel4();
		expect(testModel42.count).toEqual(4);

	});

});


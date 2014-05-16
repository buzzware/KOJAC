describe("Kojac Override", function() {


	it("meta returns the same object each time, and subclasses return a different object", function() {
		var RndModel = Ember.Object.extend({});
		var SubModel1 = RndModel.extend({});
		var SubModel2 = RndModel.extend({});

		expect( Ember.meta(RndModel) ).toBeTruthy();
		expect( Ember.meta(RndModel)===Ember.meta(RndModel)).toBeTruthy();
		expect( Ember.meta(RndModel).descs ).toBeTruthy();
		expect( Ember.meta(RndModel).descs===Ember.meta(RndModel).descs ).toBeTruthy();

		expect( Ember.meta(SubModel1) ).toBeTruthy();
		expect( Ember.meta(SubModel1)!==Ember.meta(RndModel) ).toBeTruthy();
		expect( Object.getPrototypeOf(Ember.meta(SubModel1))===Object.getPrototypeOf(Ember.meta(RndModel)) ).toBeTruthy();

		expect( Ember.meta(SubModel1).descs ).toBeTruthy();
		expect( Ember.meta(SubModel1).descs!==Ember.meta(RndModel).descs ).toBeTruthy();
		expect( Object.getPrototypeOf(Ember.meta(SubModel1).descs)===Object.getPrototypeOf(Ember.meta(RndModel).descs)).toBeTruthy();

		expect( Ember.meta(SubModel2) ).toBeTruthy();
		expect( Ember.meta(SubModel2).descs ).toBeTruthy();
		expect( Ember.meta(SubModel1)!==Ember.meta(SubModel2) ).toBeTruthy();
		expect( Ember.meta(SubModel1).descs!==Ember.meta(SubModel2).descs ).toBeTruthy();
	});

	it("instances have their own meta", function() {
		var RndModel = Ember.Object.extend({});
		var rndModel = RndModel.create();
		expect( Ember.meta(RndModel) ).toBeTruthy();
		expect( Ember.meta(rndModel) ).toBeTruthy();
		expect( Ember.meta(rndModel)!==Ember.meta(RndModel) ).toBeTruthy();
	});

	it("instance proto === class", function() {
		var RndModel = Ember.Object.extend({});
		var rndModel = RndModel.create({});
		expect(rndModel.constructor === RndModel).toBeTruthy();
		expect(Object.getPrototypeOf(RndModel) === Object.getPrototypeOf(Ember.Object)).toBeTruthy();
		expect(Object.getPrototypeOf(RndModel) !== Ember.Object).toBeTruthy();
	});

	it("override get and set", function() {
		//var RndModel = Ember.Object.extend({});
		var SubModel1 = Kojac.EmberModel.extend({
			name: Int
		});
		//var SubModel2 = RndModel.extend({});
		var subModel1 = SubModel1.create({
			name: 'fred'
		});
		console.log(subModel1.get('name'));
		subModel1.set('name','john');
		console.log(subModel1.get('name'));
	});

//	it("can modify class desc", function() {
//
//		var TestMethodType = function(aParam) {
//      this.set = function(obj, keyName, value) {
//	      var meta = Ember.meta(obj),
//	    			desc = (meta && meta.descs[keyName]);
//	    		meta.descs[keyName] = undefined;
//	      Ember.set(obj,keyName,value+value);
//	      meta.descs[keyName] = desc;
//      }
//		};
//		TestMethodType.prototype = new Ember.Descriptor();
//
//		var props = {
//			name: new TestMethodType('something')
//		};
//		var RndModel = Ember.Object.extend(props);
//
//		var rndModel = RndModel.create({});
//		rndModel.set('name','blah');
//		expect(rndModel.get('name')).toEqual('blahblah');
//	});

});
describe("EmberModel toJsono", function() {

	var productProperties = {
		name: String,
		purchases: Int,
		weight: Number,
		isMember: Boolean,
		embedded: null
	};
	var Product = Kojac.EmberModel.extend(productProperties);

	var Summer = Kojac.EmberModel.extend({
		a: Int,
		b: Int,
		sum: function() {
			return this.get('a') + this.get('b');
		}.property('a','b')
	});

	var productValues1 = {
		name: 'John',
		purchases: 56,
		weight: 12.3,
		isMember: true,
		embedded: null
	};

	var values2 = {
		colour: 'crimson',
		content: 23,
		explosive: true,
		embedded: null
	};
	
	var simpleArray = [3,4,5,true,false,"efg",3.4,null];

	it("simple values", function() {
		_.each(simpleArray,function(v){
			expect(Kojac.Utils.toJsono(v)).toEqual(v);
		})
	});

	it("array of simple values", function() {
		var jsono = Kojac.Utils.toJsono(simpleArray);
		expect(jsono).toEqual(simpleArray);
	});
	
	it("simple object", function() {
		var jsono = Kojac.Utils.toJsono(productValues1);
		expect(jsono).toEqual(productValues1);
	});

	it("simple object with embedded model", function() {
		var input = _.clone(values2);
		input.embedded = Product.create(productValues1);
		
		var actual = Kojac.Utils.toJsono(input);
		
		var expected = _.clone(values2);
		expected.embedded = productValues1;
		
		expect(actual).toEqual(expected);
	});
	
	it("simple model with embedded object", function() {
		var input = Product.create(productValues1);
		input.set('embedded',values2);
		
		var actual = Kojac.Utils.toJsono(input);
		
		var expected = _.clone(productValues1);
		expected.embedded = values2;
		
		expect(actual).toEqual(expected);
	});
	
	it("simple model", function() {
		var product1 = Product.create(productValues1);
		var jsono = Kojac.Utils.toJsono(product1);
		expect(jsono).toEqual(productValues1)
	});

	it("model with include", function(){
		var input = Summer.create({a: 17,b:28});
		var actual = Kojac.Utils.toJsono(input,{include: ['sum']});
		expect(actual).toEqual({a: 17,b:28,sum:45});
	});

	it("date toJsono", function() {
		var actual = Kojac.Utils.toJsono(new Date(2011,0,1));
		expect(actual).toEqual("2010-12-31T16:00:00.000Z");
	});

	it("date serialization", function() {
		var Product = Kojac.EmberModel.extend({
			dob: Date
		});
		var product = Product.create({dob: new Date(2011,0,1)});
		var jsono = Kojac.Utils.toJsono(product);
		expect(jsono).toEqual({
			dob: "2010-12-31T16:00:00.000Z"
		})
	});

});

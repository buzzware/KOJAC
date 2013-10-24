describe("Kojac Ember Model", function() {

	var product1Values = {
		name: String,
		purchases: Int,
		weight: Number,
		isMember: Boolean,
		start: Date
	};
	var Product1 = Kojac.EmberModel.extend(product1Values);

	// can only include static values here ie not a Date or other object
	var product2Values = {
		name: 'John',
		purchases: 56,
		weight: 12.3,
		isMember: true
	};
	var Product2 = Kojac.EmberModel.extend(product2Values);

	var wrongProductValues = {
		name: 123,
		purchases: 2.34,
		weight: [],
		isMember: 1,
		start: "2010-06-01T23:59:56+08:00"
	};

	it("extend and check null values", function() {
		var product = Product1.create();
		expect(product.name).toBeNull();
		expect(product.purchases).toBeNull();
		expect(product.weight).toBeNull();
		expect(product.isMember).toBeNull();
		expect(product.start).toBeNull();
		expect(Product1.getDefinitions()).toEqual(product1Values);
	});

	it("extend and check non-null values", function() {
		var product = Product2.create();
		expect(product.name).toBe(product2Values.name);
		expect(product.purchases).toBe(product2Values.purchases);
		expect(product.weight).toBe(product2Values.weight);
		expect(product.isMember).toBe(product2Values.isMember);
		expect(product.get('name')).toBe(product2Values.name);
		expect(product.get('purchases')).toBe(product2Values.purchases);
		expect(product.get('weight')).toBe(product2Values.weight);
		expect(product.get('isMember')).toBe(product2Values.isMember);
		expect(Product2.getDefinitions()).toEqual({
			name: String,
			purchases: Int,
			weight: Number,
			isMember: Boolean
		});
	});

	it("Ember.Object extend and create", function() {
		var product3def = {
			name: 'Fred',
			shape: 'circle'
		};
		var Product3 = Kojac.EmberModel.extend(product3def);
		var product3 = Product3.create();
		expect(product3.get('name')).toEqual('Fred');
		expect(product3.get('shape')).toEqual('circle');

		var product3 = Product3.create();
		expect(product3.get('name')).toEqual(product3def.name);
		var product3 = Product3.create({});
		expect(product3.get('name')).toEqual(product3def.name);
		var product3 = Product3.create({name: 'John', colour: 'red'});
		expect(product3.get('name')).toEqual('John');
		expect(product3.get('shape')).toEqual('circle');
		expect(product3.get('colour')).toEqual('red');
	});

	it("check create values", function() {
		var product = Product1.create(product2Values);
		expect(product.get('name')).toBe(product2Values.name);
		expect(product.get('purchases')).toBe(product2Values.purchases);
		expect(product.get('weight')).toBe(product2Values.weight);
		expect(product.get('isMember')).toBe(product2Values.isMember);
	});

	it("check create values requiring conversion", function() {
		moment().zone(8);
		var product = Product1.create(wrongProductValues);
		expect(product.get('name')).toBe('123');
		expect(product.get('purchases')).toBe(2);
		expect(product.get('weight')).toBe(null);
		expect(product.get('isMember')).toBe(true);
		expect(product.get('start')).toEqual(new Date(2010,5,1,23,59,56));
	});

	it("check set values requiring conversion", function() {
		moment().zone(8);
		var product = Product1.create();
		for (p in wrongProductValues)
			product.set(p,wrongProductValues[p]);
		//person.setProperties(wrongProductValues);
		expect(product.name).toBe('123');
		expect(product.purchases).toBe(2);
		expect(product.weight).toBe(null);
		expect(product.isMember).toBe(true);
		expect(product.start).toEqual(new Date(2010,5,1,23,59,56));
	});

	it("check setProperties values requiring conversion", function() {
		moment().zone(8);
		var product = Product1.create();
		product.setProperties(wrongProductValues);
		expect(product.name).toBe('123');
		expect(product.purchases).toBe(2);
		expect(product.weight).toBe(null);
		expect(product.isMember).toBe(true);
		expect(product.start).toEqual(new Date(2010,5,1,23,59,56));
	});

	it("check init", function() {
		var initValues = {
			name: 'Jeffery',
			purchases: 5,
			weight: 2.4,
			isMember: true
		};
		var productValuesWithInit = {
			name: 'XXX',
			purchases: 3,
			weight: 1.2,
			isMember: false,
			init: function() {
				this._super();
				for (p in initValues) {
					if (p=='weight')
						continue;
					this[p] = initValues[p];
				}
			}
		};
		var Product3 = Kojac.EmberModel.extend(productValuesWithInit);
		var product = Product3.create();
		expect(product.name).toBe(initValues.name);
		expect(product.purchases).toBe(initValues.purchases);
		expect(product.isMember).toBe(initValues.isMember);
		expect(product.weight).toBe(productValuesWithInit.weight);
	});

	it("check computed property", function() {
		var initValues = {
			first_name: 'Jeffery',
			last_name: 'Watt',
			full_name: function() {
				return this.first_name+' '+this.last_name;
			}.property()
		};
		var Cust = Ember.Object.extend(initValues);
		var cust = Cust.create();
		expect(cust.first_name).toBe(initValues.first_name);
		expect(cust.last_name).toBe(initValues.last_name);
		expect(cust.get('full_name')).toBe(initValues.first_name+' '+initValues.last_name);
	});

	it("real world example", function() {
		var App = {};
		App.FinanceProvider = Kojac.EmberModel.extend({
			id: Int,
			name: String
		});
		App.FinanceProviders = [
			App.FinanceProvider.create({
				id: 1,
				name: 'GE Automotive'
			}),
			App.FinanceProvider.create({
				id: 2,
				name: 'St George Bank'
			}),
			App.FinanceProvider.create({
				id: 3,
				name: 'Esanda ANZ'
			})
		];
		expect(App.FinanceProviders[0].get('id')).toEqual(1);
		expect(App.FinanceProviders[0].get('name')).toEqual('GE Automotive');
		expect(App.FinanceProviders[1].get('id')).toEqual(2);
		expect(App.FinanceProviders[1].get('name')).toEqual('St George Bank');
	});

});
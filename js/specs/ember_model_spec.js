describe("Kojac Ember Model", function() {

	var product1Values = {
		name: String,
		purchases: Int,
		weight: Number,
		isMember: Boolean
	};
	var Product1 = Kojac.EmberModel.extend(product1Values);

	var product2Values = {
		name: 'John',
		purchases: 56,
		weight: 12.3,
		isMember: true
	}
	var Product2 = Kojac.EmberModel.extend(product2Values);

	var wrongProductValues = {
		name: 123,
		purchases: 2.34,
		weight: [],
		isMember: 1
	};

	it("extend and check null values", function() {
		var product = Product1.create();
		expect(product.name).toBeNull();
		expect(product.purchases).toBeNull();
		expect(product.weight).toBeNull();
		expect(product.isMember).toBeNull();
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

	it("check set values requiring conversion", function() {
		var product = Product1.create();
		for (p in wrongProductValues)
			product.set(p,wrongProductValues[p]);
		//person.setProperties(wrongProductValues);
		expect(product.name).toBe('123');
		expect(product.purchases).toBe(2);
		expect(product.weight).toBe(null);
		expect(product.isMember).toBe(true);
	});

	it("check setProperties values requiring conversion", function() {
		var product = Product1.create();
		product.setProperties(wrongProductValues);
		expect(product.name).toBe('123');
		expect(product.purchases).toBe(2);
		expect(product.weight).toBe(null);
		expect(product.isMember).toBe(true);
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

});
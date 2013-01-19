/*--------------------------------------------------------------------------
 *
 *	Key Oriented JSON Application Cache (KOJAC)
 *	(c) 2011-12 Buzzware Solutions
 *  https://github.com/buzzware/KOJAC
 *
 *	KOJAC is freely distributable under the terms of an MIT-style license.
 *
 *--------------------------------------------------------------------------*/

// recommended http://www.cerebris.com/blog/2012/03/06/understanding-ember-object/
//var Person = Ember.Object.extend({
//	chromosomes: null,
//	init: function() {
//		this._super();
//		this.chromosomes = ["x"]; // everyone gets at least one X chromosome
//	}
//});

// declaring property : {chromosomes: null}
// for values, generate function that calls this._super(); then loops thru setting values

// example :
//
//Product = Kojac.EmberModel.extend({
//	name: String,
//	purchases: Int,
//	weight: Number,
//	isMember: Boolean,
//	init: function() {
//		this._super();
//		this.weight = 0.0;
//	}
//});
//
//
// 1. Create extendObject with properties: null
// 2.

Kojac.EmberModel = Ember.Object.extend({});

Kojac.EmberModel.reopenClass({

	_extend: Ember.Object.extend,

	extend: function() {
		var defs = arguments[0];
		var extender = {};
		var definitions = this.getDefinitions();
		var defaults = this.getDefaults();
		var _type;
		var _value;
		var _init;
		if (defs) {
			for (p in defs) {
				var pValue = defs[p];
				if (p=='init') {
					_init = pValue;
				} else {
					if (Kojac.FieldTypes.indexOf(pValue)>=0) { // pValue is field type
						definitions[p] = pValue;
						defaults[p] = null;
						extender[p] = null;
					} else {
						var ft=Kojac.getPropertyValueType(pValue);
						if (ft && (Kojac.SimpleTypes.indexOf(ft)>=0)) {  // pValue is simple field value
							definitions[p] = ft;
							defaults[p] = pValue;
							extender[p] = null;
						} else {  // pValue is something else
							//definitions[p] = _type;
							//defaults[p] = _value;
							extender[p] = pValue;
						}
					}
				}
			}
			extender.init = function() {  // we need to call the super init, then initialise default values, then call the given init
				this._super();
				var defaults = this.constructor.getDefaults();
				for (dp in defaults)
					this[dp] = defaults[dp];
				if (_init) {
					var _super = this._super;
					this._super = function() {};  // temporarily disable _super to make init function work like normal ember init
					_init.call(this);
					if (_super)
						this._super = _super;       // restore _super
				}
			};
		}
		var result = this._extend(extender);
		result.setDefinitions(definitions);
		result.setDefaults(defaults);
		return result;
	},

	setDefinitions: function(aDefinitions) {
		this._definitions = (aDefinitions || {});
	},

	getDefinitions: function() {
		return this._definitions || {};
	},

	setDefaults: function(aDefaults) {
		this._defaults = (aDefaults || {});
	},

	getDefaults: function() {
		return this._defaults || {};
	}

});

Kojac.EmberModel.reopen({

	___set: Kojac.EmberModel.prototype.set,
	set: function(k,v) {
		var def = this.constructor.getDefinitions();
		var t = (def && def[k]);
		if (t)
			v = Kojac.interpretValueAsType(v,t);
		return this.___set(k,v);
	},

	___get: Kojac.EmberModel.prototype.get,
	get: function(k) {
		return this.___get(k);
	},

	___setProperties: Kojac.EmberModel.prototype.setProperties,
	setProperties: function(values) {
		values = Kojac.readTypedProperties({},values,this.constructor.getDefinitions());
		return this.___setProperties(values);
	}

});

Kojac.EmberCache = Ember.Object.extend({

	cacheResults: function(aRequest) {
		this.beginPropertyChanges();
		for (var i=0;i<aRequest.ops.length;i++) {
			var op = aRequest.ops[i];
			if (op.error)
				break;
			if (op.options.cacheResults===false)
				continue;
			for (p in op.results) {
				if (op.results[p]===undefined) {
					this.set(p,undefined);
					delete this[p];
				} else {
					this.set(p,op.results[p]);
				}
			}
		}
		this.endPropertyChanges();
	},

	collectIds: function(aPrefix, aIds) {
		return Kojac.collectIds(aPrefix,aIds,this);
	}

});

Kojac.collectIds = function(aPrefix,aIds,aCache) {
	if (!aIds)
		return [];
	var result = [];
	for (var i=0;i<aIds.length;i++)
		result.push(aCache.get(aPrefix+'__'+aIds[i]));
	return result;
};

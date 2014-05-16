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


Kojac.EmberObjectFactory = Kojac.Object.extend({

	matchers: null,

	register: function(aPairs) {
		if (!aPairs)
			return;
		if (this.matchers===null)
			this.matchers = [];
		for (var i = 0; i < aPairs.length; i++)
			this.matchers.push(aPairs[i]);
	},

	emberClassFromKey: function(aKey) {
		var pair;
		var re;
		var newClass;
		for (var i = 0; i < this.matchers.length; i++) {
			pair = this.matchers[i];
			re = pair[0];
			if (!re.test(aKey))
				continue;
			newClass = pair[1];
			break;
		}
		if (newClass===undefined)
			newClass = Ember.Object;
		return newClass;
	},

	emberObjectFactoryArray: function(aArray,aKey) {
		var newClass = this.emberClassFromKey(aKey);
		var result = [];
		for (var i=0; i<aArray.length; i++) {
			var newv = newClass.create(aArray[i]);
			result.push(newv);
		}
		return result;
	},

	manufacture: function(aObject,aKey) {
		var newClass = this.emberClassFromKey(aKey);
		var newv = newClass.create(aObject);
		return newv;
	}

});

Kojac.EmberModel = Ember.Object.extend({

//	set: function(k,v) {
//		var def = this.constructor.getDefinitions();
//		var t = (def && def[k]);
//		if (t)
//			v = Kojac.interpretValueAsType(v,t);
//		return this._super(k,v);
//	},
//
//	setProperties: function(values) {
//		values = Kojac.readTypedProperties({},values,this.constructor.getDefinitions());
//		return this._super(values);
//	},

	// copy the property from source to dest
	// this could be a static fn
	toJsonoCopyFn: function(aDest,aSource,aProperty,aOptions) {
		aDest[aProperty] = Kojac.Utils.toJsono(Ember.get(aSource,aProperty),aOptions);
	},

	// return array of names, or an object and all keys will be used
	// this could be a static fn
	toPropListFn: function(aSource,aOptions) {
		var p;
		if (p = aSource && aSource.constructor && aSource.constructor.proto && aSource.constructor.proto()) {
			if ((p = Ember.meta(p)) && (p = p.descs))
				return _.keys(p);
			else
				return [];
		} else {
			return aSource;
		}
	},

	toJsono: function(aOptions) {
		return Kojac.Utils.toJsono(this,aOptions,this.toPropListFn,this.toJsonoCopyFn)
	}

});

//fullName: Ember.computed('firstName', 'lastName', function() {
//  return this.get('firstName') + ' ' + this.get('lastName');
//})

// in create, set cache with defaults merged with given values
// getter - use cacheFor
// setter - set cache with converted value
// in extend, generate with Ember.computed().cacheable(true)




Kojac.EmberModel.reopenClass({


//	var SubModel1 = RndModel.extend({
//		name: Ember.computed(function(aKey,aValue){
//			// MyClass.metaForProperty('person');
//			var m = Ember.meta(this);
//			var d = m && m.descs[aKey];
//			//var cache =  m.cache;
//			var v;
//
//			if (arguments.length==2) { // set
//				var t = d && d._meta && d._meta.type;
//				if (t)
//					v = Kojac.interpretValueAsType(aValue,t);
//				else
//					v = aValue;
//				//cache[aKey] = v;
//			} else {  // get
//				v = Ember.cacheFor(this,aKey);
//			}
//			return v;
//		}).meta({
//			type: Int
//		})
//	});


	extend: function() {
		var defs = arguments[0];
		var extender = {};
//		var definitions = this.getDefinitions();
//		var defaults = this.getDefaults();

		var _type;
		var _value;
		//var _init;
		if (defs) {
			var destType;
			var defaultValue;
			for (p in defs) {
				var pValue = defs[p];
				destType = null;
				defaultValue = null;

				if (Kojac.FieldTypes.indexOf(pValue)>=0) { // pValue is field type
					destType = pValue;
					defaultValue = null;
				} else {
					var ft=Kojac.getPropertyValueType(pValue);
					if (ft && (Kojac.SimpleTypes.indexOf(ft)>=0)) {  // pValue is simple field value
						destType = ft;
						defaultValue = pValue;
					}
				}

				if (destType) {
					extender[p] = Ember.computed(function(aKey,aValue){
						// MyClass.metaForProperty('person');
						var m = Ember.meta(this,false);
						var d = m && m.descs[aKey];
						var v;

						if (arguments.length==2) { // set
							var t = d && d._meta && d._meta.type;
							if (t)
								v = Kojac.interpretValueAsType(aValue,t);
							else
								v = aValue;
							//cache[aKey] = v;
						} else {  // get
							var cache =  m.cache;
							v = Ember.cacheFor(this,aKey);
					    if (cache && aKey in cache) {
					      return cache[aKey];
					    } else {
						    return d && d._meta && d._meta.value;
					    }
						}
						return v;
					}).meta({
						type: destType,
						value: defaultValue
					})
				} else {
					extender[p] = pValue;
				}
			}
		}
		var result = this._super(extender);
//		result.setDefinitions(definitions);
//		result.setDefaults(defaults);
		return result;
	}

//	setDefinitions: function(aDefinitions) {
//		this._definitions = (aDefinitions || {});
//	},
//
//	getDefinitions: function() {
//		return this._definitions || {};
//	},
//
//	setDefaults: function(aDefaults) {
//		this._defaults = (aDefaults || {});
//	},
//
//	getDefaults: function() {
//		return this._defaults || {};
//	},

//	__createWithMixins: Kojac.EmberModel.createWithMixins,
//	createWithMixins: function() {
//		var inputs = arguments;
//		if (inputs.length) {
//			inputs[0] = Kojac.readTypedProperties({},inputs[0],this.getDefinitions());
//		}
//		var result = this.__createWithMixins.apply(this,inputs);
//		return result;
//  },
//
//	__create: Kojac.EmberModel.create,
//	create: function() {
//		var inputs = arguments;
//		if (inputs.length) {
//			inputs[0] = Kojac.readTypedProperties({},inputs[0],this.getDefinitions());
//		}
//		var result = this.__create.apply(this,inputs);
//		return result;
//	}

});


Kojac.EmberCache = Ember.Object.extend({

	generateKey: function(aPrefix) {
		var key;
		do {
			key = aPrefix+'__'+(-_.random(1000000,2000000)).toString();
		} while (key in this);
		return key;
	},

	generateId: function(aPrefix) {
		var key;
		var id;
		do {
			id = -_.random(1000000,2000000)
			key = aPrefix+'__'+id.toString();
		} while (key in this);
		return id;
	},

	retrieve: function(k) {
		return this.get(k);
	},

	store: function(k,v) {
		this.beginPropertyChanges();
		if (v===undefined) {
			this.set(k,v);
			delete this[k];
		} else {
			this.set(k,v);
		}
		this.endPropertyChanges();
	},

	collectIds: function(aPrefix, aIds) {
		return Kojac.collectIds(aPrefix,aIds,this);
	}

});

Kojac.collectIds = function(aPrefix,aIds,aCache,aFilterFn) {
	if (!aIds)
		return [];
	var result = [];
	var item;
	for (var i=0;i<aIds.length;i++) {
		item = aCache.get(aPrefix+'__'+aIds[i]);
		if (!aFilterFn || aFilterFn(item))
			result.push(item);
	}
	return result;
};

Ember.computed.collectIds = function(aCollectionProperty,aPrefix,aModelCachePath,aFilterFn){
	if (!aPrefix)
		aPrefix = _.last(aCollectionProperty.split('.'));

  return Ember.computed(aCollectionProperty, function(){
	  var cache;
	  if (aModelCachePath)
	    cache = Ember.Handlebars.get(this,aModelCachePath);  //(aModelCachePath && Ember.get(aModelCachePath));
	  else
		  cache = this;
	  var ids = Ember.Handlebars.get(this,aCollectionProperty);
	  if (!ids)
	 		return [];
	 	var result = [];
	 	var item;
	 	for (var i=0;i<ids.length;i++) {
	 		item = cache.get(aPrefix+'__'+ids[i]);
	 		if (!aFilterFn || aFilterFn(item))
	 			result.push(item);
	 	}
	 	return result;
  }).property(aModelCachePath,aCollectionProperty);
};

Ember.computed.has_many = function(aResource,aForeignKey,aLocalPropertyPath,aModelCachePath,aFilterFn){

  return Ember.computed(function(){
	  var cache;
	  if (aModelCachePath)
	    cache = Ember.Handlebars.get(this,aModelCachePath);  //(aModelCachePath && Ember.get(aModelCachePath));
	  else
		  cache = this;
	  var localValue = Ember.Handlebars.get(this,aLocalPropertyPath);

	  if (!_.endsWith(aResource,'__'))
	    aResource = aResource+'__';

	  var results = [];
	  // get all keys that begin with aPrefix
	  var keys = _.keys(cache);
	  for (var i=0;i<keys.length;i++) {
		  var k = keys[i];
		  if (!_.beginsWith(k,aResource))
		    continue;
		  var v = cache.get(k);
		  if (!v || (v.get(aForeignKey) != localValue))
			  continue;
		  if (aFilterFn && !aFilterFn(k,v))
		    continue;
		  results.push(v);
	  }
	 	return results;
  }).property(aModelCachePath,aLocalPropertyPath);
};

Ember.computed.modelById = function(aIdProperty,aPrefix,aModelCachePath) {
	if (!aModelCachePath)
		aModelCachePath = 'App.cache';

	return Ember.computed(aIdProperty, function(){
		var id = Ember.Handlebars.get(this,aIdProperty);
		if (!id)
			return null;
		var cache = Ember.Handlebars.get(this,aModelCachePath);
		var key = keyJoin(aPrefix,id);
		if (!key || !cache)
			return null;
		return Ember.Handlebars.get(cache,key);
	}).property(aModelCachePath,aIdProperty);
};

Ember.computed.modelByIdVersioned = function(aIdProperty,aVerProperty,aPrefix,aModelCachePath) {
	if (!aModelCachePath)
		aModelCachePath = 'App.cache';

	return Ember.computed(aIdProperty, function(){
		var id = Ember.Handlebars.get(this,aIdProperty);
		var cache = Ember.Handlebars.get(this,aModelCachePath);
		if (!id || !cache)
			return null;
		var key;
		var ver = Ember.Handlebars.get(this,aVerProperty);
		if (ver) {
			id = [id,ver].join('_');
			key = keyJoin(aPrefix,id);
			return Ember.Handlebars.get(cache,key);
		} else {
			var versions = _.pickWithPrefix(cache,keyJoin(aPrefix,id)+'_');
			var v,vi;
			key = _.max(_.keys(versions), function(k){
				vi = k.lastIndexOf('_');
				return Number(k.substr(vi+1));
			});
			return key ? versions[key] : null;
		}
	}).property(aModelCachePath,aIdProperty,aVerProperty);
};





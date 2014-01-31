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

Kojac.EmberModel = Ember.Object.extend({});

Kojac.EmberModel.TypedField = function() {
  this.get = function(obj,keyName) {    // Here code was copied from Ember get to avoid endless recursion. This is more efficient but brittle for future Ember versions
	  var meta = Ember.meta(obj),
		  desc = (meta && meta.descs[keyName]),
		  ret;
	  if (Ember.ENV.MANDATORY_SETTER && meta && (meta.watching[keyName] > 0)) {
		  ret = meta.values[keyName];
	  } else {
		  ret = obj[keyName];
	  }
	  if ((ret === undefined) &&
		  ('object' === typeof obj) && !(keyName in obj) && ('function' === typeof obj.unknownProperty)) {
		  return obj.unknownProperty(keyName);
	  }
	  return ret;
  }
	this.set = function(obj,keyName,aValue) {   // here we call the standard method after removing the desc to prevent endless recursion, then put it back.
		var result;
		var def = obj.constructor.getDefinitions();
		var t = (def && def[keyName]);
		if (t)
			aValue = Kojac.interpretValueAsType(aValue,t);
		var meta = Ember.meta(obj),
			desc = (meta && meta.descs[keyName]);
		meta.descs[keyName] = undefined;
		try {
			result = Ember.set(obj,keyName,aValue);
		}
		finally {
			meta.descs[keyName] = desc;
		}
		return result;
	}
};
Kojac.EmberModel.TypedField.prototype = new Ember.Descriptor();

Kojac.EmberModel.reopenClass({

	extend: function() {
		var defs = arguments[0];
		var extender = {};
		var definitions = this.getDefinitions();
		var defaults = this.getDefaults();

		var _type;
		var _value;
		//var _init;
		if (defs) {
			for (p in defs) {
				var pValue = defs[p];
				if (Kojac.FieldTypes.indexOf(pValue)>=0) { // pValue is field type
					definitions[p] = pValue;
					defaults[p] = null;
					extender[p] = null;
				} else {
					var ft=Kojac.getPropertyValueType(pValue);
					if (ft && (Kojac.SimpleTypes.indexOf(ft)>=0)) {  // pValue is simple field value
						definitions[p] = ft;
						defaults[p] = pValue;
						extender[p] = pValue;
					} else {  // pValue is something else
						//definitions[p] = _type;
						//defaults[p] = _value;
						extender[p] = pValue;
					}
				}
			}
		}
		var result = this._super(extender);
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
	},

	__addDescs: function(aNewInstance){
		var meta = Ember.meta(aNewInstance);
		var defs = this.getDefinitions();
		if (defs) {
			for (p in defs) {
				meta.descs[p] = new Kojac.EmberModel.TypedField(aNewInstance);
			}
		}
	},


	__createWithMixins: Kojac.EmberModel.createWithMixins,
	createWithMixins: function() {
		var inputs = arguments;
		if (inputs.length) {
			inputs[0] = Kojac.readTypedProperties({},inputs[0],this.getDefinitions());
		}
		var result = this.__createWithMixins.apply(this,inputs);
		this.__addDescs(result);
		return result;
  },

	__create: Kojac.EmberModel.create,
	create: function() {
		var inputs = arguments;
		if (inputs.length) {
			inputs[0] = Kojac.readTypedProperties({},inputs[0],this.getDefinitions());
		}
		var result = this.__create.apply(this,inputs);
		this.__addDescs(result);
		return result;
	}

});

Kojac.EmberModel.reopen({

	___set: Ember.set,
	set: function(k,v) {
		var def = this.constructor.getDefinitions();
		var t = (def && def[k]);
		if (t)
			v = Kojac.interpretValueAsType(v,t);
		return this.___set(this,k,v);
	},

	___setProperties: Ember.setProperties,
	setProperties: function(values) {
		values = Kojac.readTypedProperties({},values,this.constructor.getDefinitions());
		return this.___setProperties(this,values);
	},

	// copy the property from source to dest
	// this could be a static fn
	toJsonoCopyFn: function(aDest,aSource,aProperty,aOptions) {
		aDest[aProperty] = Kojac.Utils.toJsono(Ember.get(aSource,aProperty),aOptions);
	},

	// return array of names, or an object and all keys will be used
	// this could be a static fn
	toPropListFn: function(aSource,aOptions) {
		if ("getDefinitions" in aSource.constructor)
			return aSource.constructor.getDefinitions();  // return an object to use all keys from
		else
			return aSource;    // this is a simple object, so use all keys
	},

	toJsono: function(aOptions) {
		return Kojac.Utils.toJsono(this,aOptions,this.toPropListFn,this.toJsonoCopyFn)
//		for (var p in defs)
//			result[p] = this.get(p);
//		if (includes) {
//			includes = this.getProperties(includes);
//			var v;
//			for (var p in includes) {
//				v = includes[p];
//				if (v && (typeof(v)=="object") && ("toJsono" in v))
//					includes[p] = v.toJsono();
//			}
//			_.extend(result,includes);
//		}
//		return result;
	}

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





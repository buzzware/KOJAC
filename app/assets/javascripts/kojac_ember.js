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
			var newv = new newClass();
			newv.setProperties(aArray[i]);
			result.push(newv);
		}
		return result;
	},

	emberObjectFactory: function(aObject,aKey) {
		var newClass = this.emberClassFromKey(aKey);
		var newv = new newClass();
		newv.setProperties(aObject);
		return newv;
	},

	transformResultsToValueObjects: function(aRequest) {
		for (var i=0;i<aRequest.ops.length;i++) {
			var op = aRequest.ops[i];
			if (op.error)
				break;
			if (op.options.atomise===false)
				continue;
			for (var k in op.results) {
				var v = op.results[k];
				if (!jQuery.isPlainObject(v))
					continue;
				op.results[k] = this.emberObjectFactory(v,k);
			}
		}
	}

});



//ExampleRemoteProvider = Ember.Object.extend({
//Kojac.RemoteProvider = Kojac.Object.extend({
//
//	useMockFileValues: false,
//  mockFilePath: '',
//	mockReadOperationHandler: null,
//	mockWriteOperationHandler: function(aOp) {
//		log.debug(JSON.stringify(EmberUtils.copyProperties({},aOp,null,['request'])));
//	},
//
//	handleOperationFromFiles: function(aRequest) {
//		var op = aRequest.handlers.parameter;
//
//		if (op.verb==='READ' || op.verb==='EXECUTE') {
//			if (this.mockReadOperationHandler) {
//				this.mockReadOperationHandler(op);
//			} else {
//				aRequest.handlers.waitForCallNext = true;
//				var fp = mockFilePath+op.key+'.js';
//				var data = null;
//				jQuery.ajax({url: fp, dataType: 'json', cache: false, data: data}).done(
//					function( aData ) {
//						for (p in aData)
//							op[p] = aData[p];
//						aRequest.handlers.callNext();
//					}
//				).fail(
//					function(jqXHR, textStatus) {
//						aRequest.handlers.handleError(textStatus);
//					}
//				);
//			}
//		} else {
//			if (this.mockWriteOperationHandler)
//				this.mockWriteOperationHandler(op);
//		}
//	},
//
//	handleAjaxRequest: function(aRequest) {
//		var op = aRequest.parameter;
//		aRequest.handlers.waitForCallNext = true;
//		jQuery.ajax({},function(){
//			aRequest.handlers.callNext();
//		})
//	},
//
//	addRequestHandlers: function(aRequest) {
//		if (this.useMockFileValues) {
//			for (var i=0;i<aRequest.ops.length;i++)
//				aRequest.handlers.add(this.handleOperationFromFiles,aRequest.ops[i],this);
//		} else {
//			aRequest.handlers.add(this.handleAjaxRequest,null,this);
//		}
//	}
//
//});


Kojac.EmberModel = Ember.Object.extend({});

Kojac.EmberModel.reopenClass({

	//_extend: Ember.Object.extend,

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
//				if (p=='init') {
//					_init = pValue;
//				} else {
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
	//			}
			}
//			extender.init = function() {  // we need to call the super init, then initialise default values, then call the given init
//				this._super();
//				//var defaults = this.constructor.getDefaults();
//				//for (dp in defaults)
//				//	this[dp] = defaults[dp];
//				if (_init) {
//					var _super = this._super;
//					this._super = function() {};  // temporarily disable _super to make init function work like normal ember init
//					_init.call(this);
//					if (_super)
//						this._super = _super;       // restore _super
//				}
//			};
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

	__createWithMixins: Kojac.EmberModel.createWithMixins,
	createWithMixins: function() {
		var inputs = arguments;
		if (inputs.length) {
			inputs[0] = Kojac.readTypedProperties({},inputs[0],this.getDefinitions());
		}
		return this.__createWithMixins.apply(this,inputs);
  },

	__create: Kojac.EmberModel.create,
	create: function() {
		var inputs = arguments;
		if (inputs.length) {
			inputs[0] = Kojac.readTypedProperties({},inputs[0],this.getDefinitions());
		}
		return this.__create.apply(this,inputs);
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

	toObject: function(aOptions) {
		var result = {};
		var defs = this.constructor.getDefinitions();
		var includes = aOptions && aOptions.include
		for (var p in defs)
			result[p] = this.get(p);
		if (includes) {
			includes = this.getProperties(includes);
			var v;
			for (var p in includes) {
				v = includes[p];
				if (v && (typeof(v)=="object") && ("toObject" in v))
					includes[p] = v.toObject();
			}
			_.extend(result,includes);
		}
		return result;
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

	store: function(aKeysValues) {
		this.beginPropertyChanges();
		for (p in aKeysValues) {
			if (aKeysValues[p]===undefined) {
				this.set(p,undefined);
				delete this[p];
			} else {
				this.set(p,aKeysValues[p]);
			}
		}
		this.endPropertyChanges();
	},

	cacheResults: function(aRequest) {
		this.beginPropertyChanges();
		for (var i=0;i<aRequest.ops.length;i++) {
			var op = aRequest.ops[i];
			if (op.error)
				break;
			if (op.options.cacheResults===false)
				continue;
			this.store(op.results);
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





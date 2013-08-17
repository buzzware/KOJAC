/*--------------------------------------------------------------------------
 *
 *	Key Oriented JSON Application Cache (KOJAC)
 *	(c) 2011-12 Buzzware Solutions
 *  https://github.com/buzzware/KOJAC
 *
 *	KOJAC is freely distributable under the terms of an MIT-style license.
 *
 *--------------------------------------------------------------------------*/
(function() {

// minimal plugin example
//(function(can, window, undefined){
//	var oldSetup = can.Observe.setup;
//	can.extend(can.Observe, {
//		setup : function(superClass){
//			oldSetup.apply(this, arguments);
//		}
//	});
//
////		can.extend(can.Observe.prototype, {
////		});
//
//})(this.can, this );

	MODEL_FIELD_CONVERTERS = { // these are only used when you call .serialize()
		'Int' : function( aValue ){
			return Kojac.interpretValueAsType(aValue,Int);
		},
		'Number' : function( aValue ){
			return Kojac.interpretValueAsType(aValue,Number);
		},
		'String' : function( aValue ){
			return Kojac.interpretValueAsType(aValue,String);
		},
		'Boolean' : function( aValue ){
			return Kojac.interpretValueAsType(aValue,Boolean);
		},
		'Date' : function( aValue ){
			return Kojac.interpretValueAsType(aValue,Date);
		},
		'Array' : function( aValue ){
			return Kojac.interpretValueAsType(aValue,Array);
		},
		'Object' : function( aValue ){
			return Kojac.interpretValueAsType(aValue,Object);
		}
	};

	Kojac.CanModel = can.Observe({
		fullName: 'Kojac.CanModel',
		extend: function(aFullName, aClass, aInstanceProps) {
			if ( typeof aFullName != 'string' ) {
				aInstanceProps = aClass;
				aClass = aFullName;
				aFullName = null;
			}
			if ( ! aInstanceProps ) {
				aInstanceProps = aClass;
				aClass = null;
			}
			aInstanceProps = aInstanceProps || {};
			aClass = aClass || {};

			if (aClass && (('attributes' in aClass) || ('defaults' in aClass) || ('serialize' in aClass) || ('convert' in aClass)))
				throw new Error('attributes, defaults, serialize and convert not supported');

			var attributes = {};
			var defaults = {};
			for (var p in aInstanceProps) {
				var v = aInstanceProps[p];
				var i = Kojac.FieldTypes.indexOf(v);
				if (i >= 0) {   // field type
					v = null;
					defaults[p] = v;
					attributes[p] = Kojac.FieldTypeStrings[i];
					delete aInstanceProps[p];
				} else if (_.isFunction(v)) {   // a method
					// don't touch this
				} else {        // default value
					i = Kojac.FieldTypes.indexOf(Kojac.getPropertyValueType(v));
					if (i >= 0) {
						attributes[p] = Kojac.FieldTypeStrings[i];
						defaults[p] = v;
					}
					delete aInstanceProps[p];
				}
			}
			_.extend(aClass,{
				attributes: attributes,
				defaults: defaults,
				serialize : MODEL_FIELD_CONVERTERS, // these are only used when you call .serialize()
				convert: MODEL_FIELD_CONVERTERS    // these are only used when you set properties with attr
			});
			if (aFullName)
				return can.Observe.extend.apply(this, [aFullName,aClass,aInstanceProps]);
			else
				return can.Observe.extend.apply(this, [aClass,aInstanceProps]);
		}
	},{
	});

	Kojac.CanObjectFactory = Kojac.ObjectFactory.extend({

		defaultClass: can.Observe,

		copyProperties: function(aDest,aSource) {
			return CanUtils.copyProperties(aDest,aSource);
		}

	});


	Kojac.CanCache = can.Observe({
//	convert: {
//		default: function(aValue) { return aValue; }
//	}
},{

//	__convert: function(prop, value){
//		console.log('__convert');
//		return value;
//	},

	get: function(k) {
		return this.attr(k);
	},
	set: function(k,v) {
		return this.attr(k,v);
	},

	cacheResults: function(aRequest) {
		console.log('BEGIN cacheResults')
		var results = {};
		var deletes = [];
		for (var i=0;i<aRequest.ops.length;i++) {
			var op = aRequest.ops[i];
			if (op.error)
				break;
			if (op.options.cacheResults===false)
				continue;
			for (p in op.results) {
				var v = op.results[p];
				results[p] = v;
				if (v===undefined)
					deletes.push(p);
				else
					deletes = _.without(deletes, [p]);
			}
		}
		for (p in results) {
			try {
				this.attr(p,results[p]);
			} catch (e) {
				console.log('Error when caching '+p+' : '+ e.message);
			}
		}
//		if (deletes.length) {
//			for (var i=0;i<deletes.length;i++) {
//				console.log('cacheResults remove');
//				this.removeAttr(deletes[i]);
//			}
//		}
		console.log('END cacheResults');
	},

	collectIds: function(aPrefix, aIds) {
		return Kojac.collectIds(aPrefix,aIds,this);
	},

	collectionValues: function(aCollectionKey) {
		return Kojac.collectionValues(aCollectionKey,this);
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

Kojac.collectionValues = function(aCollectionKey,aCache) {
	var ids = aCache.get(aCollectionKey);
	return Kojac.collectIds(aCollectionKey,ids,aCache);
};

})();

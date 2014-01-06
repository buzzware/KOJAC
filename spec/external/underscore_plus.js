//  underscore_plus.js
//  (c) 2013 Gary McGhee, Buzzware Solutions
//  https://github.com/buzzware/underscore_plus
//  Underscore may be freely distributed under the MIT license.

(function() {

	//BEGIN copied from underscore
	var ArrayProto = Array.prototype, ObjProto = Object.prototype, FuncProto = Function.prototype;
  // Create quick reference variables for speed access to core prototypes.
  var slice            = ArrayProto.slice;
	//END copied from underscore

_.stringify = function(aObject) {
	if (_.isString(aObject))
		return aObject;
	if (aObject===null || aObject===undefined)
		return '';
	if (aObject.toString)
		return aObject.toString();
	return '';
};

//var MAX_DUMP_DEPTH = 10;
//
//       function dumpObj(obj, name, indent, depth) {
//              if (depth > MAX_DUMP_DEPTH) {
//                     return indent + name + ": <Maximum Depth Reached>\n";
//              }
//              if (typeof obj == "object") {
//                     var child = null;
//                     var output = indent + name + "\n";
//                     indent += "\t";
//                     for (var item in obj)
//                     {
//                           try {
//                                  child = obj[item];
//                           } catch (e) {
//                                  child = "<Unable to Evaluate>";
//                           }
//                           if (typeof child == "object") {
//                                  output += dumpObj(child, item, indent, depth + 1);
//                           } else {
//                                  output += indent + item + ": " + child + "\n";
//                           }
//                     }
//                     return output;
//              } else {
//                     return obj;
//              }
//       }

_.concat = function(aArray,aAnotherArray) {
	var result = [];
	result.push.apply(result, aArray);
	result.push.apply(result, aAnotherArray);
	return result;
};

_.nameValueString = function(aObject) {
	return _.map(_.keys(aObject),function(k) { return k+'="'+_.stringify(aObject[k])+'"'}).join(' ');
};

_.classEnsure = function(aOrig,aNew) {
	if (!aOrig)
		return aNew;
	if (!aNew)
		return aOrig;
	return _.union(aOrig.split(' '),aNew.split(' '));
};

_.getPath =	function(aObject,aPath,aDefault) {
	if ((typeof aObject)=='string') {   // allow aObject to be left out and assume this
		if (arguments.length==1) {
			aPath = aObject;
			aObject = window;
		} else if (arguments.length==2) {
			aDefault = aPath;
			aPath = aObject;
			aObject = window;
		}
	}
	var nodes = aPath.split('.');
	var curr = aObject;
	for (var i=0;i<nodes.length;i++) {
		var name = nodes[i];
		if ((curr===undefined)||(curr===null))
			return aDefault;
		if ((name in curr) || curr[name]) {
			var val = curr[name];
			if ((typeof val)=='function')
				curr = val.call(curr);
			else
				curr = val;
		} else {
			return aDefault;		// name doesn't exist
		}
	}
	return curr;
}

_.moveKeys = function(aDest,aSource,aKeys) {
	if (!aSource)
		return aDest;
	if (!aKeys)
		aKeys = _.keys(aSource);
	for (var i=0;i<aKeys.length;i++) {
		var k = aKeys[i];
		if (!(k in aSource))
			continue;
		aDest[k] = aSource[k];
		delete aSource[k];
	}
	return aDest;
};

_.removeKey = function(aObject,aKey) {
	var result = aObject[aKey];
	delete aObject[aKey];
	return result;
};

// for Twitter Typeahead. See http://code.whatcould.com/2013/02/28/underscore-templates-with-twitter-typeahead.html
_.templateTypeaheadCompatible = {
  compile: function(str) {
    return new _.templateTypeaheadCompiled(str);
  }
}
_.templateTypeaheadCompiled = (function() {
  function templateTypeaheadCompiled(str) {
    this.compiledTemplate = _.template(str);
  }

  templateTypeaheadCompiled.prototype.render = function(context) {
    return this.compiledTemplate(context);
  };

  return templateTypeaheadCompiled;
})();

//	// find all dynamic objects in an array that have matching values for the contents of aAndCriteria
//	public static function ObjectArrayFind(aArray:Array, aAndCriteria:Object):Array {
//		return aArray.filter(
//			function(item:*, index:int, array:Array):Boolean {
//			// for all items in aAndCriteria, aItem has matching values
//			for (var i:String in aAndCriteria) {
//				if (aAndCriteria[i] != item[i])
//					return false;
//			}
//			return true;
//		}
//	);
//	}
//
//	// like ObjectArrayFind except only returns one object. Could be optimised to quit searching when one is found
//	// adds listener and removes on first occurrence
//	public static function ObjectArrayFindOne(aArray:Array, aAndCriteria:Object):Object {
//		var results:Array = ObjectArrayFind(aArray, aAndCriteria);
//		return results[0];
//	}
//
//	public static function ObjectArrayLookup(aArray:Array, aAndCriteria:Object, aProperty:String):Object {
//		var results:Array = ObjectArrayFind(aArray, aAndCriteria);
//		var item:Object = results[0];
//		if (!item)
//			return null;
//		return item[aProperty];
//	}

_.hasMatchingProperties = function(aObject,aCriteria) {
	for (var p in aCriteria) {
		if (!(p in aObject) || (aObject[p]!==aCriteria[p]))
			return false;
	}
	return true;
};

// find one item matching object properties
_.findByCriteria = function(aArray,aCriteria) {
	return _.find(aArray,function(obj){
		return _.hasMatchingProperties(obj,aCriteria);
	});
};

// find one item matching object properties
_.filterByCriteria = function(aArray,aCriteria) {
	return _.filter(aArray,function(obj){
		return _.hasMatchingProperties(obj,aCriteria);
	});
};

_.isObjectStrict = function(aSomething) {
	return Object.prototype.toString.call(aSomething)==='[object Object]';
}

// create an object using key,value arguments eg. createObject('a',2) returns {a: 2}
_.createObject = function() {
	var result = {};
	result[arguments[0]] = arguments[1];
	return result;
}

_.endsWith = function(aString, aSuffix) {
	var i = aString.lastIndexOf(aSuffix);
	return (i>=0 && i===aString.length-aSuffix.length);
}

_.beginsWith = function(aString, aPrefix) {
	var i = aString.indexOf(aPrefix);
	return (i==0);
}

_.chop = function(aString, aSuffix) {
	var i = aString.lastIndexOf(aSuffix);
	return (i===aString.length-aSuffix.length) ? aString.substring(0,i) : aString;
}

_.bite = function(aString, aPrefix) {
	var i = aString.indexOf(aPrefix);
	return (i===0) ? aString.substring(aPrefix.length) : aString;
}

// undefined null function arguments string number date regexp object
_.typeOf = function(aSomething) {
	if (aSomething===undefined)
		return 'undefined';
	if (aSomething===null)
		return 'null';

	var result = Object.prototype.toString.call(aSomething);
	result = _.bite(result,'[object ');
	result = _.chop(result,']');
	return result.toLowerCase();
}

	/**
	 * Clone properties that are objects or arrays, otherwise if aSource and aDestination are different, properties will be copied
	 * @param aDestination
	 * @param aSource  (optional, defaults to aSource)
	 * @return aDestination
	 */
_.cloneComplexValues = function (aDestination, aSource) {
	if (!aSource)
		aSource = aDestination;
	for (var p in aSource) {
		var t = _.typeOf(aSource[p]);
		if (t==='array' || t==='object')
			aDestination[p] = _.clone(aSource[p]);
		else if (aDestination!==aSource)
			aDestination[p] = aSource[p];
	}
	return aDestination;
}

	// http://justtalkaboutweb.com/2008/01/06/javascript-object-extension/

_.originalClone = _.originalClone || _.clone;
// Create a copy (shallow or deep) of an object from https://github.com/cederberg/underscore/commits/feature-clone
_.clone = function(obj, deep, ignoreFns) {
	if (!deep && !ignoreFns)
		return _.originalClone(obj);
  if (!_.isObject(obj) || _.isFunction(obj)) return obj;
  if (_.isDate(obj)) return new Date(obj.getTime());
  if (_.isRegExp(obj)) return new RegExp(obj.source, obj.toString().replace(/.*\//, ""));
  var isArr = (_.isArray(obj) || _.isArguments(obj));
  if (deep) {
    var func = function(memo, value, key) {
      if (!ignoreFns || !_.isFunction(value)) {
		    if (isArr)
	        memo.push(_.clone(value, true));
	      else
	        memo[key] = _.clone(value, true);
      }
      return memo;
    };
    return _.reduce(obj, func, isArr ? [] : {});
  } else {
	  var result;
		if (isArr)
			result = slice.call(obj);
	  else {
			result = {};
			var v;
			for (var p in obj) {
				v = obj[p];
				if (ignoreFns && _.isFunction(v))
					continue;
				result[p] = v;
      }
		}
		return result;
  }
};

_.randomString = function (aLength, aCharSet) {
	var result = [];

	aLength = aLength || 5;
	aCharSet = aCharSet || 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
	aCharSet = aCharSet.split('');

	while (--aLength) {
		result.push(aCharSet[Math.floor(Math.random() * aCharSet.length)]);
	}

	return result.join('');
};

_.formatNumber = function(aValue,aDecimals) {
	if (aValue===null)
		return '';
	if (!aDecimals && aDecimals!==0)
		aDecimals = 2;
	return aValue.toFixed(aDecimals);
};

_.groupDigits = function(x) {
	var parts = x.toString().split(".");
	parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
	return parts.join(".");
};

_.sum = function() {
	var result = NaN;
	for (var i=0;i<arguments.length;i++) {
		var v = arguments[i];
		if (!_.isNumber(v))
			return NaN;
		if (i==0)
			result = 0;
		result += v;
	}
	return result;
};

	_.formatCurrency = function(aNumber,aPrecision,aSymbol) {
		if (!aPrecision)
			aPrecision = 0;
		if (!aSymbol)
			aSymbol = '$';
		return _.isFinite(aNumber) ? aSymbol+_.groupDigits(_.formatNumber(aNumber,aPrecision)) : '';
	};

_.formatPercent = function(aNumber,aPrecision,aSymbol) {
	if (!aPrecision)
		aPrecision = 0;
	if (!aSymbol)
		aSymbol = '%';
	return _.isFinite(aNumber) ? _.groupDigits(_.formatNumber(aNumber*100.0,aPrecision))+aSymbol : '';
};

_.toNull = function(aValue,aDefault) {
	if (arguments.length==1)
		aDefault = null;
	return ((aValue===null) || (aValue===undefined) || (aValue===[]) || (aValue===0) || (aValue==={}) || _.isNaN(aValue)) ? aDefault : aValue;
}

_.toFinite = function(aValue,aDefault) {
	return _.toNumber(aValue,aDefault);
}

_.toInt = function(aValue,aDefault) {
	if (arguments.length==1)
		aDefault = null;
	var t = _.typeOf(aValue);
	var result;
	switch(t) {
		case 'undefined':
		case 'null':
		case 'array':
		case 'object':
		case 'function':
		case 'class':
		case 'instance':
		case 'error':
			result = aDefault;
			break;
		case 'string':
		case 'number':
			aValue = Number(aValue);
			if (!_.isFinite(aValue))
				result = aDefault;
			else
				result = Math.round(aValue);
			break;
		case 'boolean':
			result = aValue ? 1 : 0;
			break;
		default:
			result = aDefault;
			break;
	}
	return result;
};

_.toNumber = function(aValue,aDefault) {
	if (arguments.length==1)
		aDefault = null;
	var t = _.typeOf(aValue);
	var result;
	switch(t) {
		case 'undefined':
		case 'null':
		case 'array':
		case 'object':
		case 'function':
		case 'class':
		case 'instance':
		case 'error':
			result = aDefault;
			break;
		case 'string':
		case 'number':
			aValue = Number(aValue);
			if (!_.isFinite(aValue))
				result = aDefault;
			else
				result = aValue;
			break;
		case 'boolean':
			result = aValue ? 1 : 0;
			break;
		default:
			result = aDefault;
			break;
	}
	return result;
};

_.toBoolean = function(aValue,aDefault) {
	if (arguments.length==1)
		aDefault = false;
	if (aValue===true || aValue===false)
		return aValue;
	if (aValue===0)
		return false;
	if (_.isString(aValue)) {
		var t = Number(aValue);
		if (_.isFinite(t)) {
			return !!t;
		} else {
			t = aValue.toLowerCase();
			if (t==="true" || t==="yes" || t==="on")
				return true;
			if (t==="false" || t==="no" || t==="off")
				return false;
		}
	} else if (_.isNumber(aValue)) {
		return !!aValue;
	}
	return aDefault;
};

// converts simple object to array of object with id and name fields
// eg.
// _.expand_options({"cash": "Cash","consumer_mortgage": "Consumer Mortgage")
// => [{id: "cash", name:"Cash"}, {id: "consumer_mortgage",name: "Consumer Mortgage"}]
// _.expand_options(["cash","consumer_mortgage"])
// => [{id: "cash", name:"cash"}, {id: "consumer_mortgage",name: "consumer_mortgage"}]
_.expand_options = function(aObject,aIdField,aNameField) {
	if (!aIdField)
		aIdField = 'id';
	if (!aNameField)
		aNameField = 'name';
	if (_.isArray(aObject)) {
		return _.map(aObject,function(v){
			var result = {};
			result[aIdField] = v;
			result[aNameField] = String(v);
			return result;
		});
	} else {
		return _.map(aObject,function(v,k){
			var result = {};
			result[aIdField] = k;
			result[aNameField] = v;
			return result;
		});
	}
};

// returns array of keys on object beginning with aPrefix
_.keysWithPrefix = function(aObject,aPrefix) {
	var results = [];
  var keys = _.keys(aObject);
  for (var i=0;i<keys.length;i++) {
	  var k = keys[i];
	  if (!_.beginsWith(k,aPrefix))
	    continue;
	  results.push(k);
  }
	return results;
};

// returns copy of object containing only properties beginning with aPrefix
_.pickWithPrefix = function(aObject,aPrefix) {
	var result = {};
	_.each(aObject,function(v, k){
		if (!_.beginsWith(k,aPrefix))
			return;
    result[k] = v;
	});
	return result;
};

_.round = function(aNumber,aDecimals) {
	var mult = Math.pow(10, aDecimals);
	return Math.round(aNumber*mult)/mult;
};

// copies properties, excluding functions
_.copyProperties = function(aDest,aSource,aProperties,aExclude) {
	var p;
	var v;
	if (!aDest)
		aDest = {};
	if (aProperties && !_.isArray(aProperties))
		aProperties = [aProperties];
	if (aExclude && !_.isArray(aExclude))
		aExclude = [aExclude];
	if (aProperties) {
		for (var i=0;i<aProperties.length;i++) {
			p = aProperties[i];
			v = aSource[p];
			if (_.isFunction(v))
				continue;
			if (aExclude && aExclude.indexOf(p)>=0)
				continue;
			if (p in aSource) aDest[p] = v;
		}
	} else {
		for (p in aSource) {
			v = aSource[p];
			if (_.isFunction(v))
				continue;
			if (aExclude && aExclude.indexOf(p)>=0)
				continue;
			if (p in aSource) aDest[p] = v;
		}
	}
	return aDest;
};


var formatRegexes = {};
// format a string
// Usage: _.format("{0} i{2}a night{1}", "This", "mare", "s ");
// Could support _.format("{number} {street}, {suburb}", {number: 27, street: "Constant St", suburb: "Highgate"}); - might already
// see http://stackoverflow.com/questions/2534803/string-format-in-javascript/2534870#2534870
_.format = function(aFormat, aValues) {
	var src,v;
	if (_.isObject(aValues)) {
		for (p in aValues)
			aFormat = aFormat.replace(formatRegexes[p] || (formatRegexes[p] = RegExp("\\{" + p + "\\}", "gm")), aValues[p]);
	} else {
		for (var args = arguments, i = args.length; --i;)
	    aFormat = aFormat.replace(formatRegexes[i - 1] || (formatRegexes[i - 1] = RegExp("\\{" + (i - 1) + "\\}", "gm")), args[i]);
	}
	return aFormat;
};

_.randomInt = function(aValues) {
	return Math.floor(Math.random()*aValues);
};

_.randomIntRange = function(aMin,aMax) {
	return aMin + Math.floor(Math.random()*(aMax-aMin+1));
};

}).call(this);

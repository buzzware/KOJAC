//  underscore_plus.js
//  (c) 2012 Gary McGhee, Buzzware Solutions
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
_.clone = function(obj, deep) {
	if (!deep)
		return _.originalClone(obj);
  if (!_.isObject(obj) || _.isFunction(obj)) return obj;
  if (_.isDate(obj)) return new Date(obj.getTime());
  if (_.isRegExp(obj)) return new RegExp(obj.source, obj.toString().replace(/.*\//, ""));
  var isArr = (_.isArray(obj) || _.isArguments(obj));
  if (deep) {
    var func = function (memo, value, key) {
      if (isArr)
        memo.push(_.clone(value, true));
      else
        memo[key] = _.clone(value, true);
      return memo;
    };
    return _.reduce(obj, func, isArr ? [] : {});
  } else {
    return isArr ? slice.call(obj) : _.extend({}, obj);
  }
};

}).call(this);

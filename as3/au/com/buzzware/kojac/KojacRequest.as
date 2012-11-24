/*--------------------------------------------------------------------------
 *
 *	Key Oriented JSON Application Cache (KOJAC)
 *	(c) 2011-12 Buzzware Solutions
 *  https://github.com/buzzware/KOJAC
 *
 *	KOJAC is freely distributable under the terms of an MIT-style license.
 *
 *--------------------------------------------------------------------------*/
package au.com.buzzware.kojac {
import allaboutecommerce.kojac.*;

import au.com.buzzware.actiontools4.code.ObjectAndArrayUtils;

import flash.events.ErrorEvent;

public class KojacRequest {
	public var kojac:Kojac;
	public var operations:Array;
	public var options:KojacRequestOptions;
	public var handlers:HandlerStack;
	public var data:Object = {}; // for any application purpose

	public function KojacRequest() {
		handlers = new HandlerStack()
	}

	public function get operation():KojacOperation {
		return (operations && operations[0]) as KojacOperation
	}

	// An error may be set for the request eg. by HandlerStack and for each operation
	// Reading this error property will return the request error if set, or the first non-null operation.error
	protected var _error:Object;
	public function get error():Object {
		if (!_error) {
			for each (var op:KojacOperation in operations)
				if (op.error)
					return op.error;
		}
		return _error;
	}

	public function set error(value:Object):void {
		_error = value;
	}

	public function results():Object {
		var result:Object = {}
		for each (var op:KojacOperation in operations) {
			ObjectAndArrayUtils.copy_properties(result, op.results)
		}
		return result
	}

	public function result():* {
		var result_key: String = operation.result_key
		var result: *
		var op_results: Object
		for each (var op:KojacOperation in operations) {
			op_results = op.results
			if (op_results.hasOwnProperty(result_key))
				result = op_results[result_key];
		}
		return result
	}

	public function result_key(): String {
		return ObjectAndArrayUtils.getPathValue(this,'operation.result_key')
	}

	public function cacheResults():void {
		for each (var op:KojacOperation in this.operations) {
			if (op.error)
				continue;
			//trace('caching results ' + ObjectAndArrayUtils.getDynamicPropertyNames(op.results).join(','))
			ObjectAndArrayUtils.copy_properties(kojac.cache, op.results, null, [op.result_key]);
			kojac.cache[op.result_key] = op.result
		}
	}

	protected function cacheResultsHandler(aRequest:KojacRequest):void {
		cacheResults()
	}

	// convenience function for when using cacheResults=NO but you want to cache the results later
	public function pushCacheResultsHandler():void {
		handlers.push(cacheResultsHandler)
	}

}

}
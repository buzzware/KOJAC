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

import au.com.buzzware.actiontools4.code.ReflectionUtils;
import au.com.buzzware.actiontools4.code.StringUtils;

public class Kojac {

	[Bindable]
	public var cache: Object;
	public var persist: IPersistenceProvider;
	public var remote: IRemoteProvider;
	public var factory: VoFactory;

	[Bindable]
	public var statusLine: String;
	[Bindable]
	public var requestStatusCount: int = 0;

	public function Kojac(aCache: Object, aPersistenceProvider: IPersistenceProvider, aRemoteProvider: IRemoteProvider, aVoFactory: VoFactory = null) {
		statusLine = 'Genesis'
		cache = aCache
		persist = aPersistenceProvider
		remote = aRemoteProvider
		if (aVoFactory)
			factory = aVoFactory;
		else
			factory = new VoFactory();
	}

	// accept multiple keys, but at present only act on the first one
	public function read(aKeys: *, aHandler: Function = null, aOptions: Object = null): KojacRequest {
		var keys: Array = aKeys is Array ? (aKeys as Array) : [aKeys]
		var ops: Array = []
		for each (var k: String in keys) {
			var op: KojacOperation = new KojacOperation()
			op.verb = KojacOperation.READ
			op.key = k
			ops.push(op)
		}
		return performOperations(ops, aHandler, aOptions)
	}

	// eg. create({products__29: {name: 'something'}},function (aRequest: KojacRequest):void {}, {})
	// create no longer adds the created item id to any collection - that is left up to the app
	public function create(aKeysValues: Object, aHandler: Function = null, aOptions: Object = null): KojacRequest {
		var ops: Array = []
		if (aKeysValues is Array) for each (var keyValueObject: Object in aKeysValues) {
			var op: KojacOperation = new KojacOperation()
			op.verb = KojacOperation.CREATE
			for (var k: String in keyValueObject) {
				op.key = k
				op.value = keyValueObject[k]
				break;
			}
			ops.push(op)
		} else for (var k: String in aKeysValues) {
			var op: KojacOperation = new KojacOperation()
			op.verb = KojacOperation.CREATE
			op.key = k
			op.value = aKeysValues[k]
			if (op.value is ValueObject)
				op.value = ReflectionUtils.copyAllFields({}, op.value);
			ops.push(op)
		}
		return performOperations(ops, aHandler, aOptions)
	}

	public function update(aKeysValues: Object, aHandler: Function = null, aOptions: Object = null): KojacRequest {
		var ops: Array = []
		if (aKeysValues is Array) for each (var keyValueObject: Object in aKeysValues) {
			var op: KojacOperation = new KojacOperation()
			op.verb = KojacOperation.UPDATE
			for (var k: String in keyValueObject) {
				op.key = k
				op.value = keyValueObject[k]
				break;
			}
			ops.push(op)
		} else for (var k: String in aKeysValues) {
			var op: KojacOperation = new KojacOperation()
			op.verb = KojacOperation.UPDATE
			op.key = k
			op.value = aKeysValues[k]
			ops.push(op)
		}
		return performOperations(ops, aHandler, aOptions)
	}

	public function destroy(aKeys: Array, aHandler: Function = null, aOptions: Object = null): KojacRequest {
		var ops: Array = []
		if (aKeys is Array) for each (var k: String in aKeys) {
			var op: KojacOperation = new KojacOperation()
			op.verb = KojacOperation.DESTROY
			op.key = k
			op.value = aKeys[k]
			ops.push(op)
		}
		return performOperations(ops, aHandler, aOptions)
	}

	public function performOperations(aOperations: Array, aHandler: Function = null, aOptions: Object = null): KojacRequest {
		if (!aOptions)
			aOptions = new KojacRequestOptions();
		else if (!(aOptions is KojacRequestOptions))
			aOptions = new KojacRequestOptions(aOptions);
		var req: KojacRequest = new KojacRequest()
		req.kojac = this
		req.operations = aOperations
		req.options = aOptions as KojacRequestOptions
		// the handlers will be executed in the reverse order they are pushed

		if (aHandler != null)
			req.handlers.push(aHandler)
		if (req.options.cacheResults)
			req.pushCacheResultsHandler();
		if (factory)
			req.handlers.push(valueObjectFactoryHandler);
		performRequest(req)
		return req
	}


	public function valueObjectFactoryHandler(aRequest: KojacRequest): void {
		factory.transformResultsToValueObjects(aRequest)
	}


	public function requestCompleteHandler(aRequest: KojacRequest = null): void {
		requestStatusCount--
	}


	protected function performRequest(aRequest: KojacRequest): void {
		if (!aRequest.options)
			aRequest.options = new KojacRequestOptions();
		updateStatusLine(aRequest)
		switch (aRequest.options.freshness) {
			case KojacRequestOptions.FRESH:
				aRequest.handlers.push(requestCompleteHandler)
				aRequest.handlers.push(remote.performRequestHandler)
				requestStatusCount++
				aRequest.handlers.call(aRequest)
				break;
			case KojacRequestOptions.STORED_IF_AVAILABLE:
				throw new Error('KojacRequestOptions.STORED_IF_AVAILABLE not yet implemented')
				break;
			case KojacRequestOptions.CACHED_IF_AVAILABLE:
				performCacheRequest(aRequest)
				break;
			default:
				throw new Error('unknown freshness')
				break;
		}
	}

	public function updateStatusLine(aRequest: KojacRequest, aOperation: KojacOperation = null): void {
		var result: String
		if (!aOperation)
			aOperation = aRequest.operation;
		switch (aOperation.verb) {
			case KojacOperation.CREATE:
				result = 'Create';
				break;
			case KojacOperation.READ:
				result = 'Get';
				break;
			case KojacOperation.UPDATE:
				result = 'Update';
				break;
			case KojacOperation.DESTROY:
				result = 'Delete';
				break;
			case KojacOperation.CRUPDATE:
				result = 'Update';
				break;
			case KojacOperation.REPLACE:
				result = 'Update';
				break;
		}
		var resource: String = aOperation.key
		var matches: Array = resource.match(/[a-zA-Z]+/g)
		result += ' ' + matches.join(' ')
		statusLine = result
	}

	protected function performCacheRequest(aRequest: KojacRequest): void {
		throw new Error('Not yet implemented - read cache directly')
	}

	public function collectValuesOfKeys(aKeyArray: *): Array {
		var result: Array = []
		var keys: Array = aKeyArray as Array
		for each (var k: String in keys) {
			result.push(cache[k])
		}
		return result
	}

	public function collectValuesOfIds(aPrefix: String, aIds: Array): Array {
		var result: Array = []
		if (!aIds)
			return result;
		for each (var i: int in aIds) {
			result.push(cache[aPrefix + '__' + i.toString()])
		}
		return result
	}

	// this is not useful in a binding expression as it won't catch collection changes in the cache
	public function collectCollection(aKeyOrIdCollectionKey: String): Array {
		var coll: Array = cache[aKeyOrIdCollectionKey] as Array
		if (coll == null)
			return null;
		var result: Array = []
		if (coll.length == 0)
			return result;
		var isIds: Boolean = (typeof(coll[0]) == 'number')
		if (isIds)
			return collectValuesOfIds(aKeyOrIdCollectionKey, coll);
		else
			return collectValuesOfKeys(coll);
	}


	public function keyIsItem(aKey: String): Boolean {
		if (!aKey)
			return false;
		var parts: Array = aKey.split('__')
		return (parts.length > 1) && (StringUtils.toInt(parts[parts.length - 1]) > 0)
	}

	public function keyIsCollection(aKey: String): Boolean {
		if (!aKey)
			return false;
		switch (aKey) {
			case 'time':
				return false;
			case 'products':
				return true;
			case 'products__images':
				return true;
		}
		return !keyIsItem(aKey);
	}


}

}
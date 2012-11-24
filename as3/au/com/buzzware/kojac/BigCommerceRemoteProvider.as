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
import aae.product_machine.app.ProductMachineModelLocator;

import au.com.buzzware.actiontools4.air.FileUtils;
import au.com.buzzware.actiontools4.code.HttpUtils;
import au.com.buzzware.actiontools4.code.JsonUtils;
import au.com.buzzware.actiontools4.code.ObjectAndArrayUtils;
import au.com.buzzware.actiontools4.code.ReflectionUtils;
import au.com.buzzware.actiontools4.code.StringUtils;

import com.adobe.utils.ArrayUtil;

import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.TextEvent;
import flash.filesystem.File;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLVariables;

import mx.rpc.AsyncToken;

import org.httpclient.HttpClient;
import org.httpclient.Log;

[Bindable]
public class BigCommerceRemoteProvider implements IRemoteProvider {

	public var kojac:Kojac;
	public var client:HttpClient;
	protected var storeUrl:String;
	protected var auth:String;
	private const GET:String = 'GET';
	private const POST:String = 'POST';
	private const PUT:String = 'PUT';
	private const DELETE:String = 'DELETE';
	public var useMockFileValues:Boolean;

	public function BigCommerceRemoteProvider() {
		Log.level = Log.DEBUG
		client = new HttpClient();
	}

	// BEGIN IRemoteProvider

	public function performRequestHandler(aRequest:KojacRequest):void {
		aRequest.handlers.push(fixupResources);
		aRequest.handlers.push(fixupOperations);
		for each (var op:KojacOperation in aRequest.operations) {
			aRequest.handlers.push(useMockFileValues ? handleOperationFromFiles : handleOperation, op);
		}
	}

	// END IRemoteProvider

	public function fixupOperations(aRequest:KojacRequest):void {        // split result into desired keys with simple objects/array/primitive typed data. They keys here will probably relate to the keys in the request
		for each (var op:KojacOperation in aRequest.operations) {
			var oResult: * = JsonUtils.jsonDecode(op.remoteResponse as String)
			//var status: int = ObjectAndArrayUtils.getPathValue(oResult,'status') as int
			if (oResult is Error) {
				op.error = oResult
				continue;
			} else if (op.remoteStatusCode==400) {
				// looks like a validation error
				op.error = oResult
			} else if (op.verb == KojacOperation.CREATE) {
				if (!op.error) {
					var idNew:int = ObjectAndArrayUtils.getPathValue(oResult,'id') as int
					if (idNew>0) {
						op.result_key = KojacUtils.keyJoin(op.key, idNew);
						op.result = oResult
					}
				}
			} else {
				op.result_key = op.key
				op.result = oResult
			}
		}
	}

	public function fixupResources(aRequest:KojacRequest):void {
		for each (var op:KojacOperation in aRequest.operations) {
			if (op.error)
				continue;
			if (op.key=='time')
				op.result = ObjectAndArrayUtils.getPathValue(op,'result.time');
			else if (op.key=='products__images')
				atomiseFatCollectionToKeys(op,false,'products__:product_id__images');
			else if (StringUtils.matchesAny(op.key, ['products','brands']))      //,/^products__[0-9]+__images$/
				atomiseFatCollectionToKeys(op);
			else if (StringUtils.matchesAny(op.key, ['categories']))      //,/^products__[0-9]+__images$/
				atomiseFatCollectionToKeys(op,true);
		}
	}

	// product__images may be atomised into products__1__images: [] and products__2__images: []. result will be products__2__images
	private function atomiseFatCollectionToKeys(op: KojacOperation, aUseIdsInCollection: Boolean = false, aKeyPattern: String = ':key__:id'): void {
		var aIdProperty: String = 'id'
		var items: Array = op.result as Array
		if (items) {
			var ids: Array = []
			for each (var i: Object in items) {
				var tokens: Object = ReflectionUtils.copyAllFields({},i)
				tokens.key = op.key
				var k: String = StringUtils.replaceTokens(aKeyPattern,tokens)
				// the resulting key can be an item or a collection. If a collection, the value must be an item of it, not the collection itself
				var isColl: Boolean = kojac.keyIsCollection(k)
				if (isColl || op.results.hasOwnProperty(k)) {
					var existing: Array = op.results[k] as Array
					var coll: Array
					if (!existing && op.results.hasOwnProperty(k)) {
						//trace('value exists at '+k+' and not an array - will put it into our array instead of overwriting')
						coll = []
						coll.push(op.results[k])
					} else {
						coll = existing || []
					}
					coll.push(i)
					op.results[k] = coll
				} else {
					op.results[k] = i
				}
				if (aUseIdsInCollection)
					ids.push(i[aIdProperty]);
				else
					ids.push(k);
			}
			ids = ArrayUtil.createUniqueCopy(ids)
			op.result = ids
		}
	}


	//@todo handle odd chars
	public static function shortUrlFromKey(aKey:String):String {
		var result:String = StringUtils.replaceAll(aKey, '__', '/')
		return result
	}

	public static const products_id_images_regex:RegExp = /^products__([0-9]+)__images$/;

	public function handleOperation(aRequest:KojacRequest):void {
		var op:KojacOperation = aRequest.handlers.parameter as KojacOperation
		kojac.updateStatusLine(aRequest,op)
		var previousValue:*
		if (op.verb == KojacOperation.READ)
			previousValue = findKeyValueFromPreviousOperation(aRequest, op.key, op);
		if (previousValue != undefined) {
			op.result_key = op.key
			op.result = previousValue
		} else {
			// !!! if create then translate products__29__images into products__images with product_id=29
			var method:String
			var params:Object = {}
			switch (op.verb) {
				case KojacOperation.READ:
					method = GET;
					if (kojac.keyIsCollection(op.key))  // 250 is BC forced limit. Later need to handle this better because we simply lose items after 250
						params.limit = 250;
					break;
				case KojacOperation.DESTROY:
					method = DELETE;
					break;
				case KojacOperation.CREATE:
				case KojacOperation.UPDATE:
					method = (op.verb==KojacOperation.CREATE ? POST : PUT)
					if (op.value is ValueObject){
						var fields: Array = (op.value as ValueObject).fieldNamesFor(op.verb)
						ObjectAndArrayUtils.copy_properties(params,op.value,fields)
					} else if (op.value is Object) {
						ObjectAndArrayUtils.copy_properties(
							params,
							op.value,
							ReflectionUtils.getFieldNames(op.value),
							['mx_internal_uid','prototype']
						)
					}
					break;
			}
			var urlRel:String = shortUrlFromKey(op.key)
			var urlFull:String = expandShortUrl(urlRel)
			aRequest.handlers.waitForCallNext = true
			doMethod(method, urlFull, params, function (aResult:Object):void {
				if (aResult.hasOwnProperty('error')) {
					op.error = aResult.error
					op.remoteResponse = aResult.hasOwnProperty('data') ? aResult.data : null
					op.remoteStatusCode = aResult.hasOwnProperty('statusCode') ? aResult.statusCode : 0;
					aRequest.handlers.handleError(aResult['error'])
				} else {
					op.remoteResponse = aResult.data
					op.remoteStatusCode = aResult.hasOwnProperty('statusCode') ? aResult.statusCode : 0;    // a response of 204 is OK and means no content
				}
				aRequest.handlers.callNext()
			})
		}
	}

	protected function expandShortUrl(urlRel:String):String {
		var loc:ProductMachineModelLocator = ProductMachineModelLocator.instance()
		return loc.bc.store.urlApi(urlRel) + '.json'
	}

	public function handleOperationFromFiles(aRequest:KojacRequest):void {
		var loc:ProductMachineModelLocator = ProductMachineModelLocator.instance()
		var op:KojacOperation = aRequest.handlers.parameter as KojacOperation
		var previousValue:*
		if (op.verb == KojacOperation.READ)
			previousValue = findKeyValueFromPreviousOperation(aRequest, op.key, op);
		if (previousValue != undefined) {
			op.result_key = op.key
			op.result = previousValue
		} else {
			var fp: String
			if (op.key=='products' && op.verb==KojacOperation.CREATE && !op.value['categories']) {
				fp = HttpUtils.CombineUrl(loc.config.fileProviderUrl,op.key + '_categories_error.js')
			} else {
		    fp = HttpUtils.CombineUrl(loc.config.fileProviderUrl,op.key + '.js')
			}
				var file: File = FileUtils.fileFromFancyPath(fp)
				var jsons:String = FileUtils.fileToString(file);
				op.remoteResponse = jsons
				op.remoteStatusCode = 200
		}
	}


	protected function findKeyValueFromPreviousOperation(aRequest:KojacRequest, aKey:String, aCurrOp:KojacOperation):* {
		var iCurrOp:int = aRequest.operations.indexOf(aCurrOp)
		for (var i:int = 0; i < iCurrOp; i++) {
			var op:KojacOperation = aRequest.operations[i] as KojacOperation
			if (op.results.hasOwnProperty(aKey))
				return op.results[aKey];
		}
		return undefined
	}


	/*
	 see http://dougmccune.com/blog/2009/01/20/accessing-svn-repositories-with-actionscript/
	 */
	protected function doMethod(aMethod:String, aUrl:String, aParams:Object, aHandler: Function):AsyncToken {
		var loc:ProductMachineModelLocator = ProductMachineModelLocator.instance()
		var loader: URLLoader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.TEXT;
		var responseStatus: HTTPStatusEvent;

		var loaderErrorHandler: Function = function (event:Event):void {
			var s: String = (loader.data as String)
			//trace(s)
			//if (event is TextEvent)
			//	trace((event as TextEvent).text);
			aHandler({
				error: event,
				data: s,
				statusCode: responseStatus ? responseStatus.status : 0
			})
		}
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler)
		loader.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler)
		loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, function(aEvent: HTTPStatusEvent): void {
			responseStatus = aEvent
		})
		loader.addEventListener(Event.COMPLETE, function(aEvent: Event): void {
			var s: String = (loader.data as String)
			//trace(s)
			aHandler({
				data: s,
				statusCode:responseStatus.status
			})
		})

		var req:URLRequest = new URLRequest(aUrl);
		req.cacheResponse = false;
		req.useCache = false;
		req.idleTimeout = 30000
		req.method = aMethod
		req.requestHeaders = [
			new URLRequestHeader('user-agent', "curl/7.9.8 (i686-pc-linux-gnu) libcurl 7.9.8 (OpenSSL 0.9.6b) (ipv6 enabled)"), //"ProductMachine/1.0"),
			new URLRequestHeader('Authorization', "Basic " + loc.bc.store.auth()),
			new URLRequestHeader('Accept', 'application/json')
		]
		req.contentType = 'application/json'
		if (aMethod==GET) {
			req.data = ObjectAndArrayUtils.copy_properties(new URLVariables(),aParams)
		} else if ((aMethod==PUT) || (aMethod==POST)) {
			var json:String = JsonUtils.jsonEncode(aParams)
			req.data = json
		}
		var sLog: String = req.method+' '+req.url+' data: '+((req.data && req.data.toString()) || '')
		//trace(sLog)
		loader.load(req)
		return null
	}
}
}

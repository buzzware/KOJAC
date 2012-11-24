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

import aae.product_machine.app.ProductMachineModelLocator;

import au.com.buzzware.actiontools4.air.FileUtils;
import au.com.buzzware.actiontools4.code.HttpUtils;
import au.com.buzzware.actiontools4.code.JsonUtils;

import flash.filesystem.File;

[Bindable]
public class FileRemoteProvider implements IRemoteProvider {

	public var fileUrl: String;

	public function FileRemoteProvider() {
	}

	// BEGIN IRemoteProvider

	public function performRequestHandler(aRequest:KojacRequest):void {
//		aRequest.handlers.push(function (aRequest:KojacRequest):void {
//			for each (var op:KojacOperation in aRequest.operations) {
//				op.results[op.result_key] = op.result
//			}
//		})
		aRequest.handlers.push(responseHandler)
		aRequest.handlers.push(requestHandler)
	}

	// END IRemoteProvider

	//@todo handle >1 operation
	public function requestHandler(aRequest:KojacRequest):void {         // generate the request to the remote resource, and call aKojac.receiveResponse(aRequest) with result/error set when complete
		var loc: ProductMachineModelLocator = ProductMachineModelLocator.instance()
		if (aRequest.operations.length > 1)
			throw new Error('>1 operation not yet implemented');
		var op:KojacOperation = aRequest.operations[0] as KojacOperation
		var fp: String = HttpUtils.CombineUrl(fileUrl,op.key + '.js')
		var file: File = FileUtils.fileFromFancyPath(fp)
		var jsons:String = FileUtils.fileToString(file);
		if (!jsons)
			trace('File not found for '+op.key);
		//if (jsons) {
			op.remoteResponse = jsons
			op.remoteStatusCode = 200
//		} else {
//			op.remoteStatusCode = 404
//			aRequest.handlers.handleError(new Error('file not found'))
//		}
	}

	public function getKeyValueFromFile(aKey:String):String {
		return FileUtils.fileToString('data/' + aKey + '.js');
	}

	public function responseHandler(aRequest:KojacRequest):void {        // split result into desired keys with simple objects/array/primitive typed data. They keys here will probably relate to the keys in the request
		for each (var op:KojacOperation in aRequest.operations) {
			var oResult: * = JsonUtils.jsonDecode(op.remoteResponse as String)
			if (op.verb == KojacOperation.CREATE) {
				var idNew:int = oResult['id'] as int
				op.result_key = KojacUtils.keyJoin(op.key, idNew);
			} else {
				op.result_key = op.key
			}

			//splitArrayKey(op.remoteResponseBody,op.key,op.results)
			if (op.key == 'products') {
				var aIdProperty:String = 'id'
				var items:Array = op.result as Array
				if (items) {
					var ids:Array = []
					for each (var i:Object in items) {
						var k:String = op.key + '__' + i[aIdProperty]
						op.results[k] = i
						ids.push(k)
					}
					op.result = ids
				}
			}
		}
	}

}
}

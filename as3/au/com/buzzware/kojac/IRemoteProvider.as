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

	public interface IRemoteProvider {

		// Generate the request to the remote resource, set remoteResponse and remoteStatusCode and and call aRequest.handlers.callNext() when complete
		// Set aRequest.result with main result, and results with any extra data, and call aRequest.handlers.callNext() when complete
		// Split result into desired keys with simple objects/array/primitive typed data. The keys here will probably relate to the keys in the request
		function performRequestHandler(aRequest: KojacRequest): void;
		function set kojac(aKojac: Kojac): void;
		function get kojac(): Kojac;

	}
}

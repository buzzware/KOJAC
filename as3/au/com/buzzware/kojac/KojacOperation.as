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
	public class KojacOperation {

		public static const CREATE: String = 'CREATE';
		public static const READ: String = 'READ';
		public static const UPDATE: String = 'UPDATE';
		public static const DESTROY: String = 'DESTROY';
		public static const CRUPDATE: String = 'CRUPDATE';
		public static const REPLACE: String = 'REPLACE';

		public var userData: Object = {}  // for any application purpose

		// request
		public var verb: String;  // CREATE, READ, UPDATE, DESTROY, CRUPDATE, REPLACE
		public var key: String;
		public var value: *;

		// response
		public var result_key:String;     // the key the result will be stored under. For create, it is the item, while key is the collection
		public var results: Object = {};  // for additional results received when getting the main result
		public var error: Object;
		public var remoteResponse:*;
		public var remoteStatusCode:int;

		public function get result(): * {
			if (!result_key)
				return null;
			return results[result_key]
		}

		public function set result(aValue: *): void {
			if (!result_key)
				throw new Error("Can't write result when result_key is not set");
			results[result_key] = aValue
		}
	}
}

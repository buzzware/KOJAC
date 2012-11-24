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
import au.com.buzzware.actiontools4.code.ObjectAndArrayUtils;

public dynamic class KojacRequestOptions {
	public static const FRESH:int = 0;    // get from freshed source ie. remote store
	public static const STORED_IF_AVAILABLE:int = 1;
	public static const CACHED_IF_AVAILABLE:int = 2;

	public static const NO:int = 0;
	public static const YES:int = 1;

	public var freshness: int = FRESH;
	public var cacheResults: int = 1;

	public function KojacRequestOptions(aObject: Object = null) {
		if (aObject)
			ObjectAndArrayUtils.copy_properties(this,aObject);
	}

}
}

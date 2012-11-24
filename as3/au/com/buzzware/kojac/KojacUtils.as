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
import au.com.buzzware.actiontools4.code.StringUtils;

public class KojacUtils {

	public static function idsFromFatCollection(aCollection: Array): Array {
		return ObjectAndArrayUtils.ObjectArrayExtractPropertyValues(aCollection,'id')
	}

	public static function keyCollectionFromIds(ids:Array, aKeyPrefix:String):Array {
		return ids.map(function (e:*, ...r):* {
			return aKeyPrefix + '__' + e.toString()
		})
	}

	public static function keysFromFatCollection(aCollection:Array, aCollectionKey:String): Array {
		var ids: Array = idsFromFatCollection(aCollection)
		return keyCollectionFromIds(ids, aCollectionKey);
	}

	public static function keyJoin(...args): String {
		var result: String
		for each (var i: * in args) {
			if (!result)
				result = i.toString();
			else
				result += '__' + i.toString();
		}
		return result;
	}

	public static function getTrailingId(aKey: String): int {
		if (!aKey)
			return 0;
		var parts: Array = aKey.split('__')
		if (!parts.length)
			return 0;
		return StringUtils.toInt(parts[parts.length-1])
	}

}
}

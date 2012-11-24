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

	public class WormPersistenceProvider implements IPersistenceProvider {
    public function WormPersistenceProvider() {
    }

		public function write(aKey: String,  aValue: String): void {
			throw new Error('NYI')
	  }
    public function read(aKey: String): String {
	    throw new Error('NYI')
	    return null
    }
    public function remove(aKey: String): void {
	    throw new Error('NYI')
    }
	}
}

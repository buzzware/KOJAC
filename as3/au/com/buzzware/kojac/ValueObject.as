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

import au.com.buzzware.actiontools4.code.BindableObject;
import au.com.buzzware.actiontools4.code.ObjectAndArrayUtils;

import flash.events.Event;
import mx.events.PropertyChangeEvent;

public dynamic class ValueObject extends BindableObject {

	// probably include key and collection fields here
	public var __fieldsChanged: Array = []
	public var __trackFieldsChanged: Boolean;

	public function ValueObject() {
		addEventListener(PropertyChangeEvent.PROPERTY_CHANGE,_handlePropertyChange)
	}

	protected var __changedCount: int;

	public function get _changeCount(): int {
		return __changedCount
	}

	public function resetChangeCount(): void {
		__changedCount = 0
	}

	public function clearFieldsChanged(): void {
		__fieldsChanged = []
	}

	protected function _handlePropertyChange(aEvent: PropertyChangeEvent): void {
		var p: String = aEvent.property.toString()
		if (p.charAt(0)=='_')
			return;
		__changedCount++;
		if (__trackFieldsChanged) {
			if (__fieldsChanged.indexOf(p)==-1)
				__fieldsChanged.push(p);
		}
	}

	public function fieldNamesFor(aVerb: String, aFields: Array = null): Array {
		return []
	}

	public function fieldValuesFor(aVerb: String, aFields: Array = null): Object {
		var fields: Array = fieldNamesFor(aVerb,aFields)
		var result: Object = ObjectAndArrayUtils.copy_properties({},this,fields)
		return result
	}

	public function setProperties(aSource: Object,  aFields: Array = null, aExcludeFields: Array = null): ValueObject {
		ObjectAndArrayUtils.copy_properties(this,aSource,aFields,aExcludeFields)
		return this
	}
}
}

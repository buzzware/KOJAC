package au.com.buzzware.kojac {
import au.com.buzzware.actiontools4.code.BindableObject;
import au.com.buzzware.actiontools4.code.DateUtils;
import au.com.buzzware.actiontools4.code.JsonUtils;
import au.com.buzzware.actiontools4.code.ReflectionUtils;
import au.com.buzzware.actiontools4.code.StringUtils;

import flash.utils.describeType;

import mx.collections.ArrayCollection;

public class VoFactory {

	public var newValueObjectFunction: Function;

	public function VoFactory(aNewValueObjectFunction: Function = null) {
		newValueObjectFunction = (aNewValueObjectFunction || defaultNewValueObjectFunction)
	}

	public function newValueObject(aSource: Object, aHint: *): ValueObject {
		var f: Function = (newValueObjectFunction || defaultNewValueObjectFunction)
		return f(aSource, aHint)
	}

	public function defaultNewValueObjectFunction(aSource: Object, aHint: *): ValueObject {
		if (aHint is Class)
			return new aHint();
		return null
	}

	// override this
	public function transformResultsToValueObjects(aRequest: KojacRequest): void {
	}

	//
	//
	//	From JSONO
	//
	//

	public static function ensureJsono(aSource: Object): Object {
		var result: Object = aSource
		if (aSource is String)
			result = JsonUtils.jsonDecode(aSource as String);
		return result
	}

	public static function nullValueForType(aTypeName: String): * {
		switch (aTypeName) {
			case 'int':
				return 0;
			case 'Number':
				return NaN;
			case 'Boolean':
				return false;
			default:
				return null;
		}
	}

	// aValue may be any valid json field type
	public function valueFromJsono(aValue: *, aDestType: String = null, aDestSubType: String = null): * {
		var result: * = null
// convert aSourceType to destType !!!
		aDestType = (aDestType && ReflectionUtils.shortName(aDestType))
		if (!aDestType)
			return aValue;
		switch (ReflectionUtils.getClassName(aValue)) {
			case 'Array':
				if (aDestType == 'Array') {
					result = []
					for each (var i: * in aValue) {
						result.push(valueFromJsono(i, aDestSubType))
					}
					if (aDestType == 'mx.collections::ArrayCollection')
						result = new ArrayCollection(result);
				} else {
					result = nullValueForType(aDestType)
				}
				break;
			case 'String':
				result = aValue
				if (aDestType == 'Date')
					result = DateUtils.parseW3C(result as String)
				break;
			case 'Object':
				switch (aDestType) {
					case 'Object':
						result = aValue;
						break;
					case 'BindableObject':
						result = new BindableObject(aValue);
						break;
					default:
						if (aValue is Object) {
							/*
							 var f:DecimalValueObjectFactory = DecimalValueObjectFactory.defaultInstance()
							 var c: Class
							 var className: String = aDestType
							 if (className) {
							 result = f.VoFromObjectClassName(aValue,className)
							 } else {
							 c = f.classFromTag(aValue['recordClass'])
							 if (c)
							 result = f.VoFromObjectClass(aValue,c);
							 }
							 if (!result)
							 result = aValue;
							 */
							result = aValue;
						} else {
							result = nullValueForType(aDestType)
						}
						break;
				}
				break;
			case 'Number':
			case 'int':
				switch (aDestType) {
					case 'Number':
					case 'int':
						result = aValue;
						break;
					case 'String':
						if (isNaN(aValue))
							result = null;
						else
							result = StringUtils.formatDecimals(aValue, 8);
						break;
					case 'Boolean':
						result = !!aValue;
						break;
					default:
						result = nullValueForType(aDestType)
				}
				break;
			case 'Boolean':
				if (aDestType == 'Boolean')
					result = aValue;
				else
					result = nullValueForType(aDestType);
				break;
			case 'null':
				result = nullValueForType(aDestType)
				break;
			//default:
			//	trace('setFieldFromJSONO: Warning ! Unsupported type ' + ReflectionUtils.getClassName(aValue))
		}
		return result
	}


	public function fieldFromJSONO(aVo: Object, aJsono: Object, aFieldName: String, aValue: *, aVoFieldType: String = null): void {
		aJsono = ensureJsono(aJsono)
		if (!aVoFieldType)
			aVoFieldType = ReflectionUtils.getFieldType(aVo, aFieldName);
		var subType: String
		var cls: Class = ReflectionUtils.getClass(aVo)
		if (!!cls && (aVoFieldType == 'mx.collections::ArrayCollection' || aVoFieldType == 'Array'))
			subType = ReflectionUtils.attributeMetadataValue(cls, aFieldName, 'Deserializer', 'toClass');
		var result: * = valueFromJsono(aValue, aVoFieldType, subType);
		aVo[aFieldName] = result
	}


	// copies fields from given JSONO to fresh VO
	public function voFieldsFromJsono(aVo: Object, aJsono: Object): void {
		aJsono = ensureJsono(aJsono)
		var fieldsWithClassNames: Object = ReflectionUtils.getFieldsWithClassNames(aJsono);
		for (var f: String in fieldsWithClassNames) {
			try {
				fieldFromJSONO(aVo, aJsono, f, aJsono[f], fieldsWithClassNames[f])
			} catch (e: Error) {
				//if ((e is ReferenceError) && (e.errorID == 1056))
				//logger.warn("Data property "+f+" doesn't exist on object of class "+MiscUtils.ClassName(me));
				//	trace("Data property " + f + " doesn't exist on object of class " + ReflectionUtils.getClassName(aVo));
				//else
				trace(e.message);
			}
		}
	}


	public function voFromJsono(aJsono: Object, aHint: * = null): ValueObject {
		aJsono = ensureJsono(aJsono)
		var obj: ValueObject = newValueObject(aJsono, aHint) || new ValueObject()
		if (obj)
			voFieldsFromJsono(obj, aJsono);
		return obj
	}

	// turns a JSONO array or single object into a VO array
	public function vosFromJsono(aJsono: Object, aHint: *): Array {
		aJsono = ensureJsono(aJsono)
		var input: Array = (aJsono is Array) ? aJsono as Array : [aJsono]
		var result: Array = []
		for each (var i: Object in input) {
			var t: String = typeof(i)
			if (t == 'object')
				result.push(voFromJsono(i, aHint));
			else
				result.push(i);
		}
		return result
	}


	//
	//
	//	To JSONO
	//
	//


	public function valueToJSONO(aValue: *): * {
		var result: *
		if (aValue is ValueObject) {
			result = voFieldsToJsono(aValue)
		} else {
			var t: String = ReflectionUtils.getClassName(aValue)
			switch (t) {
				case 'Date':
					result = DateUtils.toW3CSimpleDate(aValue);
					break;
				case 'Boolean':
					result = (aValue ? 1 : 0);
					break;
				case 'ArrayCollection':
					result = (aValue as ArrayCollection).source;
					if (result) {
						var origArray: Array = result
						result = []
						for each (var i: * in origArray) {
							result.push(valueToJSONO(i));
						}
					}
					break;
				case 'null':
				case 'int':
				case 'Number':
				case 'String':
				case 'Array':
					result = aValue;
					break;
				case 'Object':
				case 'BindableObject':
					result = {}
					for (var p: String in aValue) {
						if (p == 'mx_internal_uid')
							continue;
						result[p] = valueToJSONO(aValue[p])
					}
					break;
				default:
					result = null;
					break;
			}
		}
		return result;
	}

	public function fieldToJSONO(aJSONO: Object, aFieldName: String, aValue: *): * {
		var result: * = valueToJSONO(aValue);
		return aJSONO[aFieldName] = result
	}

	public function voFieldsToJsono(aVo: ValueObject, aJSONO: Object = null, aProperties: Array = null, aExceptProperties: Array = null): Object {
		aJSONO ||= new Object()
		if (!aProperties)
			aProperties = ReflectionUtils.getFieldNames(aVo);
		var c: Class = ReflectionUtils.getClass(aVo)
		var describeTypeXml: XML = describeType(c)
		for each (var p: String in aProperties) {
			if (p == 'mx_internal_uid')
				continue;
			if (aExceptProperties && (aExceptProperties.indexOf(p) >= 0))
				continue;
			if (ReflectionUtils.attributeMetadataValue(c, p, 'Serializer', 'dont', describeTypeXml) == 'true')
				continue;
			fieldToJSONO(aJSONO, p, aVo[p])
		}
		return aJSONO
	}

}
}

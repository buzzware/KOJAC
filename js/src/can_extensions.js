CanUtils = {

	isCanObject: function(aObject) {
		return aObject instanceof can.Construct;
	},

	attr: function(aObject,aProperty,aValue) {
		if (!aObject)
			return undefined;
		if (this.isCanObject(aObject)) {
			return aObject.attr(aProperty,aValue)
		} else {
			if (arguments.length===3) {  // set
				return aObject[aProperty] = aValue;
			} else {
				return aObject[aProperty]
			}
		}
	},

	copyProperties: function(aDest,aSource,aProperties,aExclude) {
		var p;
		var v;
		if (aProperties) {
			for (var i=0;i<aProperties.length;i++) {
				p = aProperties[i];
				if (aExclude && aExclude.indexOf(p)>=0)
					continue;
				v = this.attr(aSource,p);
				if (v!==undefined)
					this.attr(aDest,p,v);
			}
		} else {
			for (p in aSource) {
				if (aExclude && aExclude.indexOf(p)>=0)
					continue;
				v = this.attr(aSource,p);
				if (v!==undefined)
					this.attr(aDest,p,v);
			}
		}
		return aDest;
	}

};

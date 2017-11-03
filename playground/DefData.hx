import classy.core.Def;
import classy.core.RawValue;

class DefData extends Def {
	public var increaseValue:Int;
	public var limits:LimitsDef;

	public static inline function fromRawValue(raw:RawValue):DefData {
		return __fromRawValue(raw);
	}

	public inline function toRawValue():RawValue {
		return __toRawValue();
	}
}

class LimitsDef extends Def {
	public var counterLimit:Int;
}

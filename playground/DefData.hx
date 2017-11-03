import classy.core.Def;
import classy.core.RawValue;

class DefData extends Def {
	public var increaseValue:Int;

	public static inline function fromRawValue(raw:RawValue):DefData {
		return __fromRawValue(raw);
	}

	public inline function toRawValue():RawValue {
		return __toRawValue();
	}
}

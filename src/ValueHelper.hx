@:access(Value)
class ValueHelper<T:Value> implements Helper<T> {
	inline function new() {}
	static var instance = new ValueHelper<Value>();

	public static inline function get<T:Value>():ValueHelper<T> {
		return cast instance; // it's all the same
	}

	public inline function link(value:T, parent:ValueBase, name:String):Void {
		value.__link(parent, name);
	}

	public inline function unlink(value:T):Void {
		value.__unlink();
	}

	@:pure
	public inline function toRawValue(value:T):RawValue {
		return value.__toRawValue();
	}
}

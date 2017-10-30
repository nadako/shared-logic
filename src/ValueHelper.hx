@:access(Value)
class ValueHelper<T:Value> implements Helper<T> {
	public inline function new() {}

	public inline function link(value:T, parent:ValueBase, name:String):Void {
		value.__link(parent, name);
	}

	public inline function unlink(value:T):Void {
		value.__unlink();
	}
}

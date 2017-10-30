interface Helper<T> {
	function link(value:T, parent:ValueBase, name:String):Void;
	function unlink(value:T):Void;
	@:pure function toRawValue(value:T):RawValue;
}

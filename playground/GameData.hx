import classy.core.Value;

class GameData extends Value {
	public var counter:Int;
	public var player:Player;

	public static inline function fromRawValue(raw)
		return __fromRawValue(raw);

	public inline function setup(transaction, changes)
		return __setup(transaction, changes);
}

class Player extends Value {
	public var name:String;
}

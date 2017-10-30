import classy.core.RawValue;
import classy.core.Transaction;
import classy.core.DbChanges;

enum MyEnum {
	A;
	B(a:Int);
	C(a:Int, b:Player);
}

class Player extends Value {
	public var some:String;
}

class GameData extends Value {
	var value:MyEnum;

	public function new() {}

	public inline function setup(transaction, dbChanges) {
		__setup(transaction, dbChanges);
	}

	public inline function toRawValue() return __toRawValue();
	public static inline function fromRawValue(raw) return __fromRawValue(raw);
}

class Main {
	static function main() {
		var raw:RawValue = {};

		var data = GameData.fromRawValue(raw);

		var transaction = new Transaction();
		var dbChanges = new DbChanges();
		data.setup(transaction, dbChanges);

		trace(haxe.Json.stringify(data.toRawValue()));
	}
}

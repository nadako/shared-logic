import classy.core.RawValue;
import classy.core.Transaction;
import classy.core.DbChanges;

enum MyEnum {
	A;
	B(v:Int);
	C(v:Player);
	// B(a:Int);
	// C(a:Int, b:Player);
	// D(e:MyEnum2);
}

enum MyEnum2 {
	A(v:Some);
}

class Player extends Value {
	public var some:String;
	public function new() some = "Hi";
}

class Some extends Value {
	public var some:String;
	public function new() some = "Hi";
}

class GameData extends Value {
	public var value:MyEnum;

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

		var player = new Player();
		data.value = A;

		// data.value = C(10, player);
		// player.some = "hi";

		// var some = new Some();
		// data.value = D(A(some));
		// some.some = "LOL";

		for (change in dbChanges.commit())
			trace(haxe.Json.stringify(change));
		// trace(haxe.Json.stringify(data.toRawValue()));
	}
}

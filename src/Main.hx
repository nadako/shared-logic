import classy.core.RawValue;
import classy.core.Transaction;
import classy.core.DbChanges;

enum MyEnum {
	A;
	B(a:Int);
	C(a:Int, b:Player);
	D(e:MyEnum2);
}

enum MyEnum2 {
	A;
	B(v:Some);
}

class Player extends Value {
	public var some:String;
	public function new() some = "Hi";
}

class Some extends Value {
	public var some:String;
	public function new() some = "Hi";
}

class Data extends Value {
	public var value:MyEnum;
	public function new() {};
}

class GameData extends Value {
	public var arr:ArrayValue<MyEnum>;

	public function new() {}

	public inline function setup(transaction, dbChanges) {
		__setup(transaction, dbChanges);
	}

	public inline function toRawValue() return __toRawValue();
	public static inline function fromRawValue(raw) return __fromRawValue(raw);
}

class Main {
	static function main() {
		var raw:RawValue = {
			arr: [],
		};

		var data = GameData.fromRawValue(raw);
		// var data = new GameData();

		var transaction = new Transaction();
		var dbChanges = new DbChanges();
		data.setup(transaction, dbChanges);

		// var player = new Player();
		// data.value = A;

		// data.value = C(10, player);
		// player.some = "hi";

		var some = new Some();
		data.arr.push(D(B(some)));
		// data.data = new Data();
		// data.data.value = D(A(some));
		some.some = "LOL";

		for (change in dbChanges.commit())
			trace(haxe.Json.stringify(change));
		// trace(haxe.Json.stringify(data.toRawValue()));
	}
}

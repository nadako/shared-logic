class GameData extends Value {
	public var player:Player;
	public var items:ArrayValue<Int>;

	public function new() {}

	public inline function setup(transaction, dbChanges) {
		__setup(transaction, dbChanges);
	}

	public inline function toRawValue() return __toRawValue();
	public static inline function fromRawValue(raw) return __fromRawValue(raw);
}

class Player extends Value {
	public var name:String;
	public var resources:Resources;

	public function new(name) {
		this.name = name;
		this.resources = new Resources();
	}
}

class Resources extends Value {
	public var gold:Int;

	public function new() {
		gold = 0;
	}
}

class Main {
	static function main() {
		var raw:RawValue = {
			player: {
				name: "Dan",
				resources: {
					gold: 1000
				}
			},
			items: [1,2,3]
		};

		var data = GameData.fromRawValue(raw);

		var transaction = new Transaction();
		var dbChanges = new DbChanges();
		data.setup(transaction, dbChanges);

		data.player = new Player("Dan");

		data.player.name = "John";
		data.player.resources.gold = 100;
		data.items.push(4);
		data.items.push(5);
		data.items.pop();

		trace(haxe.Json.stringify(dbChanges.commit(), "  "));
	}
}

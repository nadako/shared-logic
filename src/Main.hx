class GameData extends Value {
	public var player:Player;

	public function new() {}

	public inline function setup(transaction, dbChanges) {
		__setup(transaction, dbChanges);
	}

	public function toRawValue() return __toRawValue();
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
		var transaction = new Transaction();
		var dbChanges = new DbChanges();

		var data = new GameData();
		data.setup(transaction, dbChanges);

		data.player = new Player("Dan");
		// transaction.commit();

		data.player.name = "John";
		data.player.resources.gold = 100;
		// trace(data);

		// transaction.rollback();

		// trace(data);
		// trace(data.toRawValue());
		// trace(haxe.Json.stringify(@:privateAccess dbChanges.changes));
	}
}

import utest.Assert.*;
import classy.core.Value;
import classy.core.Transaction;
import classy.core.DbChange;
import classy.core.DbChanges;

class Player extends Value {
	public var name:String;
	public var level:Int;
	public function new() {}

	public function setup(transaction, dbChanges) __setup(transaction, dbChanges);
	public static function fromRaw(raw) return __fromRawValue(raw);
	public function toRaw() return __toRawValue();
}

class TestValueSimple {
	public function new() {}

	public function setup() {};
	public function teardown() {};

	public function testUnset() {
		var player = new Player();
		player.name = "John";
		player.level = 42;
		equals("John", player.name);
		equals(42, player.level);
	}

	public function testFromRawValue() {
		var player = Player.fromRaw({name: "Mary", level: 3});
		is(player, Player);
		equals("Mary", player.name);
		equals(3, player.level);
	}

	public function testToRawValue() {
		var player = new Player();
		player.name = "John";
		player.level = 42;
		same({name: "John", level: 42}, player.toRaw());
	}

	public function testTransaction() {
		var player = new Player();
		player.name = "John";
		player.level = 42;

		var t = new Transaction();
		player.setup(t, null);
		player.name = "Mary";
		t.commit();
		equals("Mary", player.name);

		player.level++;
		player.name = null;
		t.rollback();
		equals(42, player.level);
		equals("Mary", player.name);
	}

	public function testChanges() {
		var changes = new DbChanges();
		var player = new Player();
		player.setup(null, changes);

		player.name = "John";
		player.level = 42;
		player.name = null;
		player.level++;

		same(
			[
				DbChange.set(["name"], "John"),
				DbChange.set(["level"], 42),
				DbChange.delete(["name"]),
				DbChange.set(["level"], 43),
			],
			changes.commit()
		);
	}
}

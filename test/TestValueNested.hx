import utest.Assert.*;
import classy.core.Value;
import classy.core.Transaction;
import classy.core.DbChange;
import classy.core.DbChanges;

class GameData extends Value {
	public var player:PlayerData;
	public function new() {
		player = new PlayerData();
	}

	public function setup(transaction, dbChanges) __setup(transaction, dbChanges);
	public static function fromRaw(raw) return __fromRawValue(raw);
	public function toRaw() return __toRawValue();
}

class PlayerData extends Value {
	public var resources:Resources;
	public function new() {
		resources = new Resources();
	}
}

class Resources extends Value {
	public var gold:Int;
	public var real:Int;
	public function new() {
		gold = real = 0;
	}
}

class TestValueNested {
	public function new() {}

	public function setup() {};
	public function teardown() {};

	public function testFromRawValue() {
		var data = GameData.fromRaw({
			player: {
				resources: {
					gold: 100,
					real: 500,
				}
			}
		});
		is(data, GameData);
		is(data.player, PlayerData);
		is(data.player.resources, Resources);
		equals(data.player.resources.gold, 100);
		equals(data.player.resources.real, 500);
	}

	public function testToRawValue() {
		var data = new GameData();
		data.player.resources.gold = 300;
		data.player.resources.real = 500;
		same(
			{
				player: {
					resources: {
						gold: 300,
						real: 500
					}
				}
			},
			data.toRaw()
		);
	}

	public function testTransaction() {
		var data = new GameData();

		var t = new Transaction();
		data.setup(t, null);

		data.player.resources.gold = 30;
		t.rollback();
		equals(0, data.player.resources.gold);

		var resources = data.player.resources;
		data.player.resources = null;
		resources.real = 500;
		t.rollback();
		equals(0, data.player.resources.real);
		equals(0, resources.real);
		same(resources, data.player.resources);
	}
}

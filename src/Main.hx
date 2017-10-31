import classy.core.Value;
import classy.core.ArrayValue;
import classy.core.Transaction;
import classy.core.DbChanges;

class GameData extends Value {
	public var player:Player;

	public function new() {
		player = new Player();
	}

	public function setup(transaction, dbChanges) __setup(transaction, dbChanges);
	public function toRawValue() return __toRawValue();
}

class Player extends Value {
	public var heroes:ArrayValue<Hero>;

	public function new() {
		heroes = new ArrayValue();
	}
}

class Hero extends Value {
	public var name:String;
	public var state:HeroState;

	public function new(name) {
		this.name = name;
		state = Free;
	}
}

enum HeroState {
	Free;
	InSquad;
	OnMap(placeId:Int);
	AtWar(warData:HeroWarData);
}

class HeroWarData extends Value {
	public var attackCount:Int;
	public function new() {
		attackCount = 0;
	}
}

class Main {
	static function main() {
		var data = new GameData();

		var hero = new Hero("Sicario");
		hero.state = AtWar(new HeroWarData());
		data.player.heroes.push(hero);

		var transaction = new Transaction();
		var dbChanges = new DbChanges();
		data.setup(transaction, dbChanges);

		trace(haxe.Json.stringify(data.toRawValue()));

		for (hero in data.player.heroes) {
			switch hero.state {
				case Free | InSquad | OnMap(_): trace("not at war!");
				case AtWar(warData):
					warData.attackCount++;
			}
		}

		for (change in dbChanges.commit())
			trace(haxe.Json.stringify(change));

		trace(haxe.Json.stringify(data.toRawValue()));
	}
}

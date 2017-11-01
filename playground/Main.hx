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
	public static function fromRawValue(raw) return __fromRawValue(raw);
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
		var data = GameData.fromRawValue({
			player: {
				heroes: [
					{
						name: "Sicario",
						state: "Free"
					}
				]
			}
		});

		var hero = new Hero("Sicario");
		hero.state = AtWar(new HeroWarData());
		data.player.heroes.push(hero);

		var transaction = new Transaction();
		var dbChanges = new DbChanges();
		data.setup(transaction, dbChanges);

		for (hero in data.player.heroes) {
			switch hero.state {
				case Free:
					trace('${hero.name} is free!');
				case InSquad:
					trace('${hero.name} is in squad!');
				case OnMap(placeId):
					trace('${hero.name} is on map (hero place id = $placeId)!');
				case AtWar(warData):
					trace('${hero.name} is at war, increasing attack count ${warData.attackCount}!');
					warData.attackCount++;
			}
		}

		for (change in dbChanges.commit())
			trace("CHANGE: " + haxe.Json.stringify(change));

		trace("STATE: " + haxe.Json.stringify(data.toRawValue()));
	}
}

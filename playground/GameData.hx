import classy.core.Value;
import classy.core.ArrayValue;
import classy.core.StringMapValue;
import classy.core.IntMapValue;

class GameData extends Value {
	public var counter:Int;
	public var player:Player;
	public var heroes:StringMapValue<HeroId,Int>;
	public var map:IntMapValue<MapId,MapItem>;

	public static inline function fromRawValue(raw)
		return __fromRawValue(raw);

	public inline function setup(transaction, changes)
		return __setup(transaction, changes);
}

enum Gender {
	Male;
	Female;
	Fluid;
}

abstract HeroId(String) to String {}
abstract ChestId(String) {}

abstract MapId(Int) to Int {}

class MapItem extends Value {
	public var name:String;
	public var x:Int;
	public var y:Int;
}

enum InventoryItem {
	LotteryTicket;
	HeroParts(heroId:HeroId, amount:Int);
	Chest(chestId:ChestId);
}

class Player extends Value {
	public var name:String;
	public var gender:Gender;
	public var inventory:ArrayValue<InventoryItem>;
}

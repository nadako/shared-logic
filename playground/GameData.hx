import classy.core.Value;
import classy.core.IntMapValue;

import DefData.HeroType;

class GameData extends Value {
	public var exp:Int;
	public var gold:Int;
	public var premium:Bool;
	public var heroes:HeroesData;

	public static inline function fromRawValue(raw)
		return __fromRawValue(raw);

	public inline function setup(transaction, changes)
		return __setup(transaction, changes);
}

abstract HeroId(Int) to Int {
	public inline function new(id) this = id;
}

class HeroesData extends Value {
	public var data:IntMapValue<HeroId,Hero>;
	var nextId:Int;

	public inline function makeHeroId():HeroId {
		return new HeroId(nextId++);
	}
}

class Hero extends Value {
	public var type:HeroType;
	public var level:Int;

	public function new(type, level) {
		this.type = type;
		this.level = level;
	}
}

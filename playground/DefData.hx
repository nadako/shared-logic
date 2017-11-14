import classy.core.Def;
import classy.core.ArrayDef;
import classy.core.RawValue;

class DefData extends Def {
	public var clickExp:Int;
	public var clickRewards:ArrayDef<ClickRewardEntryDef>;

	public static inline function fromRawValue(raw:RawValue):DefData {
		return __fromRawValue(raw);
	}
}

class ClickRewardEntryDef extends Def {
	public var exp:Int;
	public var reward:ClickRewardDef;
}

abstract HeroType(String) {}

enum ClickRewardDef {
	PremiumStatus;
	Gold(amount:Int);
	Hero(type:HeroType, level:Int);
}

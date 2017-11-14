import GameData;
import DefData;

class Commands {
	var context:Context;

	public function new(context) {
		this.context = context;
	}

	public function click() {
		var oldExp = context.data.exp;
		var newExp = oldExp + context.defs.clickExp;
		context.data.exp = newExp;
		for (entry in context.defs.clickRewards) {
			if (oldExp < entry.exp && newExp >= entry.exp) {
				giveReward(entry.reward);
			}
		}
	}

	function giveReward(reward:ClickRewardDef) {
		switch reward {
			case PremiumStatus:
				context.data.premium = true;

			case Gold(amount):
				context.data.gold += amount;

			case Hero(type, level):
				var heroId = context.data.heroes.makeHeroId();
				context.data.heroes.data.set(heroId, new Hero(type, level));
		}
	}
}

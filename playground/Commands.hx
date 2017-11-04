class Commands {
	var context:Context;
	public var player:PlayerCommands;

	public function new(context) {
		this.context = context;
		player = new PlayerCommands(context);
	}

	public function increaseCounter() {
		var counter = context.data.counter + context.defs.increaseValue;
		if (counter > context.defs.limits.counterLimit)
			counter = context.defs.limits.counterLimit;
		context.data.counter = counter;
	}
}

class PlayerCommands {
	var context:Context;

	public function new(context) {
		this.context = context;
	}

	public function changeName(newName:String) {
		trace('Changing name from ${context.data.player.name} to $newName at ${context.commandTime}');
		context.data.player.name = newName;
	}

	public function checkInventory() {
		for (item in context.data.player.inventory) {
			switch item {
				case LotteryTicket:
					trace("yay, a lottery ticket");
				case HeroParts(heroId, amount):
					trace('call 911 he`s got $amount $heroId`s body parts!');
				case Chest(chestId):
					trace('ooh so what`s in that $chestId?');
			}
		}
	}
}

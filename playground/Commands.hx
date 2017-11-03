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
}

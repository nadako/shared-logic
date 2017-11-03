class Commands {
	var context:Context;
	@:commands var player:PlayerCommands;

	public function new(context) {
		this.context = context;
		player = new PlayerCommands(context);
	}

	function increaseCounter() {
		context.data.counter += context.defs.increaseValue;
	}
}

class PlayerCommands {
	var context:Context;

	public function new(context) {
		this.context = context;
	}

	function changeName(newName:String) {
		trace('Changing name from ${context.data.player.name} to $newName at ${context.commandTime}');
		context.data.player.name = newName;
	}
}

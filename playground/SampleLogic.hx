import classy.core.Transaction;
import classy.core.DbChange;
import classy.core.DbChanges;
import classy.core.RawValue;
import classy.core.Value;

class GameData extends Value {
	public var counter:Int;
	public var player:Player;

	public static inline function fromRawValue(raw) return __fromRawValue(raw);
	public inline function setup(transaction, changes) return __setup(transaction, changes);
}

class Player extends Value {
	public var name:String;
}

abstract Time(Float) {}

class Context {
	public var data(default,null):GameData;
	public var commandTime(default,null):Time;

	public function new() {}

	@:allow(SampleLogic)
	inline function setup(data) this.data = data;

	@:allow(SampleLogic)
	inline function setCommandTime(time) this.commandTime = time;
}

@:keep @:expose("Logic")
class SampleLogic {
	var transaction = new Transaction();
	var dbChanges = new DbChanges();
	var context:Context;
	var commands:CommandExecutor<Commands>;

	public function new() {
		context = new Context();
		commands = new CommandExecutor<Commands>(new Commands(context));
	}

	public function setup(rawData:RawValue) {
		var data = GameData.fromRawValue(rawData);
		data.setup(transaction, dbChanges);
		context.setup(data);
	}

	public function execute(time:Time, name:String, args:Array<Any>):Array<DbChange> {
		context.setCommandTime(time);
		try {
			commands.execute(name, args);
		} catch (e:Any) {
			transaction.rollback();
			dbChanges.rollback();
			js.Lib.rethrow();
		}
		transaction.commit();
		var changes = dbChanges.commit();
		return changes;
	}
}

class Commands {
	var context:Context;
	@:commands var player:PlayerCommands;

	public function new(context) {
		this.context = context;
		player = new PlayerCommands(context);
	}

	function increaseCounter() {
		context.data.counter++;
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

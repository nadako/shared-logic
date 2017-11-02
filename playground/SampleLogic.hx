import classy.core.Transaction;
import classy.core.DbChange;
import classy.core.DbChanges;
import classy.core.RawValue;
import classy.core.Value;

class GameData extends Value {
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

	public inline function setup(data) {
		this.data = data;
	}

	@:allow(SampleLogic)
	inline function setCommandTime(time) this.commandTime = time;
}

@:keep @:expose("Logic")
class SampleLogic {
	var transaction = new Transaction();
	var dbChanges = new DbChanges();
	var context:Context;
	var commands:Executor;

	public function new() {
		context = new Context();
		commands = new Executor(context);
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

class Executor {
	var context:Context;

	public function new(context) {
		this.context = context;
	}

	public function execute(name:String, args:Array<Any>) {
		// TODO: this should be auto-generated
		switch [name, args] {
			case ["changeName", [newName]]:
				changeName(newName);
			case _:
				throw 'Unknown command or invalid number of arguments (name=$name, args=$args)';
		}
	}

	function changeName(newName:String) {
		trace('Changing name from ${context.data.player.name} to $newName at ${context.commandTime}');
		context.data.player.name = newName;
	}
}

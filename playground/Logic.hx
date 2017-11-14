import classy.core.Transaction;
import classy.core.DbChange;
import classy.core.DbChanges;
import classy.core.RawValue;
import classy.core.CommandExecutor;

@:keep @:expose
class Logic {
	var transaction = new Transaction();
	var dbChanges = new DbChanges();
	var context:Context;
	var commands:CommandExecutor<Commands>;

	public function new() {
		context = new Context();
		commands = new CommandExecutor(new Commands(context));
	}

	public function setup(data:GameData, defs:DefData) {
		data.setup(transaction, dbChanges);
		context.setup(data, defs);
	}

	public function execute(time:Time, name:String, args:Array<Any>):Array<DbChange> {
		context.setCommandTime(time);
		try {
			commands.execute(name, args);
		} catch (e:Any) {
			transaction.rollback();
			dbChanges.rollback();
			#if js
			js.Lib.rethrow();
			#else
			cs.Lib.rethrow(e);
			#end
		}
		transaction.commit();
		var changes = dbChanges.commit();
		return changes;
	}

	@:expose("convertData")
	static function convertData(raw:RawValue):GameData {
		return GameData.fromRawValue(raw);
	}

	@:expose("convertDefs")
	static function convertDefs(raw:RawValue):DefData {
		return DefData.fromRawValue(raw);
	}
}

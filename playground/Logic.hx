import classy.core.Transaction;
import classy.core.DbChange;
import classy.core.DbChanges;
import classy.core.RawValue;

@:keep @:expose
class Logic {
	var transaction = new Transaction();
	var dbChanges = new DbChanges();
	var context:Context;
	var commands:CommandExecutor<Commands>;

	public function new() {
		context = new Context();
		commands = new CommandExecutor<Commands>(new Commands(context));
	}

	public function setup(rawData:RawValue, rawDefs:RawValue) {
		var data = GameData.fromRawValue(rawData);
		data.setup(transaction, dbChanges);
		var defs = DefData.fromRawValue(rawDefs);
		context.setup(data, defs);
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

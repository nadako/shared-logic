import DbChanges.DbChange;

class ArrayValue<T> extends ValueBase {
	final array:Array<T>;
	var helper:Null<Helper<T>>;

	public function new() {
		this.array = [];
	}

	public inline function get(index:Int):T return array[index];

	public function push(value:T):Int {
		var result = array.push(value);
		if (helper != null)
			helper.link(value, this, "" + array.length);
		if (__transaction != null)
			__transaction.addRollback(() -> array.pop());
		if (__dbChanges != null)
			__dbChanges.register(DbChange.push(__makeFieldPath([]), if (helper != null) helper.toRawValue(value) else value));
		return result;
	}

	public function pop():Null<T> {
		var wasNonEmpty = array.length > 0;
		var value = array.pop();
		if (helper != null)
			helper.unlink(value);
		if (wasNonEmpty && __transaction != null)
			__transaction.addRollback(() -> array.push(value));
		if (__dbChanges != null)
			__dbChanges.register(DbChange.pop(__makeFieldPath([])));
		return value;
	}

	static function __fromRawValue<T>(raw:RawValue, converter:RawValueConverter<T>):ArrayValue<T> {
		var instance = new ArrayValue();
		for (value in (raw : Array<RawValue>))
			instance.array.push(if (converter != null) converter.fromRawValue(value) else value);
		return instance;
	}
}

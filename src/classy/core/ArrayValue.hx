package classy.core;

/**
	Обёртка-Value над упорядоченным массивом, генерирующая чейнджи и умеющая (де)сериализоваться.
**/
@:forward(
	length, push, pop,
	__setup, __setHelpers, __link, __unlink, __toRawValue
)
abstract ArrayValue<T>(ArrayValueImpl<T>) from ArrayValueImpl<T> {
	public inline function new() this = new ArrayValueImpl();
	@:op([]) inline function get(index:Int):T return this.array[index];
	@:op([]) inline function set(index:Int, value:T):T return this.set(index, value);
	public inline function iterator() return new ArrayIterator(this.array);
}

// TODO: this should be private :-/
class ArrayValueImpl<T> extends ValueBase {
	public final array:Array<T>;
	public var helper:Null<Helper<T>>;

	public var length(get,never):Int;
	inline function get_length() return array.length;

	public function new() {
		this.array = [];
	}

	override function __setup(transaction:Transaction, dbChanges:DbChanges) {
		__transaction = transaction;
		__dbChanges = dbChanges;
		if (helper != null) {
			for (value in array) {
				helper.setup(value, transaction, dbChanges);
			}
		}
	}

	inline function __setHelpers(helper:Helper<T>) {
		this.helper = helper;
	}

	public function set(index:Int, value:T):T {
		if (index < 0 || index >= array.length)
			throw "Out of bounds"; // fuck ugly JS-like behaviour
		var oldValue = array[index];
		if (oldValue != value) {
			var name = "" + index;
			if (helper != null) {
				helper.unlink(oldValue);
				helper.link(value, this, name);
			}
			array[index] = value;
			if (__transaction != null)
				__transaction.addRollback(() -> array[index] = oldValue);
			if (__dbChanges != null)
				__dbChanges.register(DbChange.set(__makeFieldPath([name]), if (helper != null) helper.toRawValue(value) else value));
		}
		return value;
	}

	public function push(value:T):Int {
		var name = "" + array.length;
		var result = array.push(value);
		if (helper != null)
			helper.link(value, this, name);
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
		var instance = new ArrayValueImpl();
		for (value in (raw : Array<RawValue>))
			instance.array.push(if (converter != null) converter.fromRawValue(value) else value);
		return instance;
	}


	@:pure
	override function __toRawValue():RawValue {
		var raw = [];
		for (value in array) {
			raw.push(if (helper != null) helper.toRawValue(value) else value);
		}
		return raw;
	}
}

private class ArrayIterator<T> {
	final array:Array<T>;
	final length:Int;
	var index:Int;
	public inline function new(arr) {
		array = arr;
		length = arr.length;
		index = 0;
	}
	public inline function hasNext() return index < length;
	public inline function next() return array[index++];
}

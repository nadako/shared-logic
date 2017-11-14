package classy.core;

import classy.core.ArrayValue.ArrayIterator;

/**
	Ридонли обёртка-Def над упорядоченным массивом умеющая (де)сериализоваться.
**/
@:forward(length, push, pop, __toRawValue)
@:forwardStatics(__fromRawValue)
abstract ArrayDef<T>(ArrayDefImpl<T>) from ArrayDefImpl<T> {
	public inline function new() this = new ArrayDefImpl();
	@:op([]) inline function get(index:Int):T return this.array[index];
	public inline function iterator() return new ArrayIterator(this.array);
}

class ArrayDefImpl<T> extends DefBase {
	public final array:Array<T>;

	public var length(get,never):Int;
	inline function get_length() return array.length;

	public function new() {
		this.array = [];
	}

	static function __fromRawValue<T>(raw:RawValue, converter:RawValueConverter<T>):ArrayDef<T> {
		var instance = new ArrayDefImpl();
		for (value in (raw : Array<RawValue>))
			instance.array.push(if (converter != null) converter.fromRawValue(value) else value);
		return instance;
	}

	@:pure
	override function __toRawValue():RawValue {
		throw "TODO"; // needs "helper"
	}
}

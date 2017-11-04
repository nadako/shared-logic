package classy.core;

private typedef UnderlyingMap<K,V> = js.Map<K, V>; // TODO: C#

class MapValueBase<K, V> extends ValueBase {
	var map:UnderlyingMap<K,V>;
	var helper:Null<Helper<V>>;

	public function new() {
		map = initUnderlyingMap();
	}

	function initUnderlyingMap():UnderlyingMap<K,V> throw "abstract";

	public inline function get(key:K):Null<V> {
		return map.get(key);
	}

	public function set(key:K, value:V) {
		var oldValue = map.get(key);
		if (oldValue != value) {
			map.set(key, value);
			if (__transaction != null) {
				if (oldValue != null)
					__transaction.addRollback(() -> map.set(key, oldValue));
				else
					__transaction.addRollback(() -> map.delete(key));
			}
			if (__dbChanges != null)
				__dbChanges.register(DbChange.set(__makeFieldPath([__keyToString(key)]), if (helper != null) helper.toRawValue(value) else value));
		}
	}

	public function remove(key:K) {
		var oldValue = map.get(key);
		if (oldValue != null) {
			map.delete(key);
			if (__transaction != null)
				__transaction.addRollback(() -> map.set(key, oldValue));
			if (__dbChanges != null)
				__dbChanges.register(DbChange.delete(__makeFieldPath([__keyToString(key)])));
		}
	}

	inline function __setHelpers(helper:Helper<V>) {
		this.helper = helper;
	}

	function __initFromValue(raw:RawValue, converter:RawValueConverter<V>) {
		for (key in js.Object.keys(raw)) {
			var value = raw[cast key];
			map.set(__keyFromString(key), if (converter != null) converter.fromRawValue(value) else value);
		}
	}

	function __keyToString(key:K):String return cast key;
	function __keyFromString(str:String):K return cast str;

	@:pure
	override function __toRawValue():RawValue {
		var raw = new haxe.DynamicAccess();

		inline function setRawValue(key, value) {
			raw[key] = if (helper != null) helper.toRawValue(value) else value;
		}

		#if js
		map.forEach((value, key, _) -> setRawValue(__keyToString(key), value));
		#else
		for (key in map.keys()) setRawValue(key, map.get(key));
		#end

		return raw;
	}
}

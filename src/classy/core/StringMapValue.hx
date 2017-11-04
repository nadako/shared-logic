package classy.core;

private typedef UnderlyingMap<V> = js.Map<String, V>; // TODO: C#

class StringMapValue<@:basic K:String, V> extends ValueBase {
	var map:UnderlyingMap<V>;
	var helper:Null<Helper<V>>;

	public function new() {
		map = new UnderlyingMap();
	}

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
				__dbChanges.register(DbChange.set(__makeFieldPath([key]), if (helper != null) helper.toRawValue(value) else value));
		}
	}

	public function remove(key:K) {
		var oldValue = map.get(key);
		if (oldValue != null) {
			map.delete(key);
			if (__transaction != null)
				__transaction.addRollback(() -> map.set(key, oldValue));
			if (__dbChanges != null)
				__dbChanges.register(DbChange.delete(__makeFieldPath([key])));
		}
	}

	inline function __setHelpers(helper:Helper<V>) {
		this.helper = helper;
	}

	static function __fromRawValue<K:String,V>(raw:RawValue, converter:RawValueConverter<V>):StringMapValue<K,V> {
		var raw = (raw : haxe.DynamicAccess<RawValue>);
		var instance = new StringMapValue();
		for (key in raw.keys()) {
			var value = raw[key];
			instance.map.set(key, if (converter != null) converter.fromRawValue(value) else value);
		}
		return instance;
	}

	@:pure
	override function __toRawValue():RawValue {
		var raw = new haxe.DynamicAccess();

		inline function setRawValue(key, value) {
			raw[key] = if (helper != null) helper.toRawValue(value) else value;
		}

		#if js
		map.forEach((value, key, _) -> setRawValue(key, value));
		#else
		for (key in map.keys()) setRawValue(key, map.get(key));
		#end

		return raw;
	}
}

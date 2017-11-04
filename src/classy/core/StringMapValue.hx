package classy.core;

class StringMapValue<@:basic K:String, V> extends MapValueBase<K,V> {
	override function initUnderlyingMap() {
		return new js.Map<K,V>();
	}

	static function __fromRawValue<K:String,V>(raw:RawValue, converter:RawValueConverter<V>):StringMapValue<K,V> {
		var instance = new StringMapValue();
		instance.__initFromValue(raw, converter);
		return instance;
	}
}

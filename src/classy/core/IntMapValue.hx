package classy.core;

class IntMapValue<@:basic K:Int, V> extends MapValueBase<K,V> {
	override function initUnderlyingMap() {
		return new js.Map<K,V>();
	}

	static function __fromRawValue<K:Int,V>(raw:RawValue, converter:RawValueConverter<V>):IntMapValue<K,V> {
		var instance = new IntMapValue();
		instance.__initFromValue(raw, converter);
		return instance;
	}

	override function __keyToString(key:K):String return "" + cast key;
	override function __keyFromString(str:String):K return untyped parseInt(str);
}

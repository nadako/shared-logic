package classy.core;

/**
	Объект-"помощник" для типа T.
	Передаётся в объекты параметризованных типов, чтобы они знали, как линковать и сериализовать своих детей.
**/
interface Helper<T> {
	function link(value:T, parent:ValueBase, name:String):Void;
	function unlink(value:T):Void;
	@:pure function toRawValue(value:T):RawValue;
}

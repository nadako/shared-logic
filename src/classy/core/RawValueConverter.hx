package classy.core;

/**
	Конвертер из "сырого значения" в значение типа T.
	Объекты этого типа нужны, когда необходимо распарсить коллекцию или другой параметризованный тип.
**/
interface RawValueConverter<T> {
	@:pure
	function fromRawValue(raw:RawValue):T;
}

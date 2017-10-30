interface RawValueConverter<T> {
	@:pure
	function fromRawValue(raw:RawValue):T;
}

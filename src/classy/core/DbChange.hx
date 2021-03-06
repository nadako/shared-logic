package classy.core;

/**
	Абстракция над "чейнджом" БД.
	Такие объекты сервер ожидает получить после выполнения команды, чтобы отложенно применить из на данные стейта.
**/
abstract DbChange(RawValue) {
	public inline static function set(path:Array<String>, value:RawValue):DbChange
		return cast {kind: "set", path: path, value: value};

	public inline static function delete(path:Array<String>):DbChange
		return cast {kind: "delete", path: path};

	public inline static function push(path:Array<String>, value:RawValue):DbChange
		return cast {kind: "push", path: path, value: value};

	public inline static function pop(path:Array<String>):DbChange
		return cast {kind: "pop", path: path};
}

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

class DbChanges {
	var changes:Array<DbChange>;

	public function new() {
		changes = [];
	}

	public inline function register(change) {
		changes.push(change);
	}

	public function commit() {
		var committedChanges = changes;
		changes = [];
		return committedChanges;
	}

	public inline function rollback() {
		changes = [];
	}
}

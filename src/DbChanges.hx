typedef DbChange = {
	var path:Array<String>;
	var value:RawValue;
}

class DbChanges {
	var changes:Array<DbChange>;

	public function new() {
		changes = [];
	}

	public inline function register(change) {
		changes.push(change);
	}

	public function clear() {
		changes = [];
	}
}

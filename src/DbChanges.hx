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

	public function commit() {
		var committedChanges = changes;
		changes = [];
		return committedChanges;
	}

	public inline function rollback() {
		changes = [];
	}
}

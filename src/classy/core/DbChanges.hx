package classy.core;

/**
	"Транзакция" чейнджей БД.
	Каждое изменение прилинкованного объекта добавляет сюда чейндж.
**/
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

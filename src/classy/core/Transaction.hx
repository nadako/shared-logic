package classy.core;

typedef Rollback = () -> Void;

class Transaction {
	var rollbacks:Array<Rollback>;

	public function new() {
		rollbacks = [];
	}

	public inline function addRollback(rollback) {
		rollbacks.push(rollback);
	}

	public inline function commit() {
		rollbacks = [];
	}

	public function rollback() {
		var len = rollbacks.length;
		while (len-- > 0) {
			rollbacks[len]();
		}
		rollbacks = [];
	}
}

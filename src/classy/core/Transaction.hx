package classy.core;

/** Функция отката значения в предыдущее. **/
typedef Rollback = () -> Void;

/**
	Транзакция - хранит функции отката установленных значений.
	Для каждого изменения данных сюда добавляется функция, откатывающая значение в предыдущее.
	При откате эти функции вызываются в обратном порядке.
**/
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

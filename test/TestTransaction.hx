import utest.Assert.*;
import classy.core.Transaction;

class TestTransaction {
	var t:Transaction;

	public function new() {}

	public function setup() t = new Transaction();
	public function teardown() t = null;

	public function test() {
		var value = 1;
		t.addRollback(() -> value = 2);
		t.rollback();
		equals(2, value);

		value = 1;
		t.rollback();
		equals(1, value);

		t.addRollback(() -> value = 2);
		t.commit();
		t.rollback();
		equals(1, value);

		t.addRollback(() -> value = 2);
		t.addRollback(() -> value = 3);
		t.rollback();
		equals(2, value);
	}
}

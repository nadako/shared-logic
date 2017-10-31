import utest.Assert.*;
import classy.core.DbChange;
import classy.core.DbChanges;

class TestDbChanges {
	var t:DbChanges;

	public function new() {}

	public function setup() t = new DbChanges();
	public function teardown() t = null;

	public function test() {
		var change1 = DbChange.set(["player", "name"], "John");
		var change2 = DbChange.set(["player", "level"], 42);
		t.register(change1);
		t.register(change2);
		same([change1, change2], t.commit());
		same([], t.commit());

		t.register(change1);
		t.register(change2);
		t.rollback();
		same([], t.commit());
	}
}

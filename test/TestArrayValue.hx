import utest.Assert.*;
import classy.core.ArrayValue;
import classy.core.Value;
import classy.core.Transaction;
import classy.core.DbChange;
import classy.core.DbChanges;

class TestArrayValue {
	public function new() {}

	public function setup() {};
	public function teardown() {};

	public function testBasicFunctions() {
		var a = new ArrayValue();
		a.push(10);
		a.push(20);
		equals(2, a.length);
		a.pop();
		equals(1, a.length);
		a.push(30);
		a[0] = 20;
		equals(20, a[0]);
		same([20, 30], [for (v in a) v]);
	}
}

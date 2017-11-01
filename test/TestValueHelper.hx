import utest.Assert.*;
import classy.core.ValueHelper;
import classy.core.Transaction;
import classy.core.DbChanges;
import classy.core.Value;

class Test1 extends Value {
	var name:String;
	public function new() name = "Test";
}
class Test2 extends Value {}

class TestValueHelper {
	public function new() {}

	function testSingleton() {
		var helper1:ValueHelper<Test1> = ValueHelper.get();
		var helper2:ValueHelper<Test2> = ValueHelper.get();
		equals(helper1, helper2); // same instance because it doensn't matter
	}

	function testFunctionality() @:privateAccess {
		var helper = new ValueHelper();
		var parent = new Test1();
		var object = new Test1();

		helper.link(object, parent, "some");
		equals(parent, object.__parent);
		equals("some", object.__name);

		helper.unlink(object);
		equals(null, object.__parent);
		equals(null, object.__name);

		same({name: "Test"}, helper.toRawValue(object));

		var t = new Transaction(), c = new DbChanges();
		helper.setup(object, t, c);
		equals(t, object.__transaction);
		equals(c, object.__dbChanges);
	}
}
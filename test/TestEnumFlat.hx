import utest.Assert.*;
import classy.core.Value;
import classy.core.DbChange;
import classy.core.DbChanges;

enum SimpleEnum {
	A;
	B;
}

class Data extends Value {
	public var simple:SimpleEnum;
	public function new() {}
}

class TestEnumFlat {
	public function new() {}

	public function testFromRawValue() @:privateAccess {
		var data = Data.__fromRawValue({simple: "A"});
		equals(A, data.simple);
		var data = Data.__fromRawValue({simple: "B"});
		equals(B, data.simple);
	}

	public function testToRawValue() @:privateAccess {
		var data = new Data();
		data.simple = A;
		same({simple: "A"}, data.__toRawValue());
		data.simple = B;
		same({simple: "B"}, data.__toRawValue());
	}

	public function testSetup() @:privateAccess {
		var data = new Data();
		data.simple = A;
		data.__setup(null, null);
		pass(); // no failures - nice \o/
	}

	public function testChanges() @:privateAccess {
		var data = new Data();
		var t = new DbChanges();
		data.__setup(null, t);

		data.simple = A;
		same([DbChange.set(["simple"], "A")], t.commit());

		data.simple = B;
		same([DbChange.set(["simple"], "B")], t.commit());
	}
}

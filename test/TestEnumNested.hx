import utest.Assert.*;
import classy.core.Value;
import classy.core.Transaction;
import classy.core.DbChange;
import classy.core.DbChanges;

enum NestedEnum {
	A;
	B(i:Inner);
	C(e:NestedEnum);
}

class Inner extends Value {
	public var count:Int;
	public function new(c=0) count = c;
}

class NestedData extends Value {
	public var nested:NestedEnum;
	public function new() {}
}

class TestEnumNested {
	public function new() {}

	public function testFromRawValue() @:privateAccess {
		var data = NestedData.__fromRawValue({nested: "A"});
		equals(A, data.nested);

		var data = NestedData.__fromRawValue({nested: {"$tag": "B", i: {count: 42}}});
		switch data.nested {
			case B(i):
				equals(i.__parent, data);
				equals(i.__name, "nested.i");
				is(i, Inner);
				equals(i.count, 42);
			case _: fail();
		}

		var data = NestedData.__fromRawValue({nested: {"$tag": "C", e: "A"}});
		switch data.nested {
			case C(A): pass();
			case _: fail();
		}
	}

	public function testToRawValue() @:privateAccess {
		var data = new NestedData();
		data.nested = A;
		same({nested: "A"}, data.__toRawValue());

		data.nested = B(new Inner(42));
		same({nested: {"$tag": "B", i: {count: 42}}}, data.__toRawValue());

		var i = new Inner(42);
		data.nested = C(B(i));
		same({nested: {"$tag": "C", e: {"$tag": "B", i: {count: 42}}}}, data.__toRawValue());
	}

	public function testSetup() @:privateAccess {
		var data = new NestedData();
		var i = new Inner();
		data.nested = C(B(i));
		var t = new Transaction(), c = new DbChanges();
		data.__setup(t, c);
		equals(t, i.__transaction);
		equals(c, i.__dbChanges);
	}

	public function testChanges() @:privateAccess {
		var data = new NestedData();
		var c = new DbChanges();
		data.__setup(null, c);

		var i = new Inner();
		data.nested = C(B(i));
		same([DbChange.set(["nested"], {"$tag": "C", e: {"$tag": "B", i: {count: 0}}})], c.commit());

		i.count++;
		same([DbChange.set(["nested", "e", "i", "count"], 1)], c.commit());
	}
}

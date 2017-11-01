import utest.Assert.*;
import classy.core.ArrayValue;
import classy.core.RawValue;
import classy.core.ValueBase;
import classy.core.RawValueConverter;
import classy.core.Helper;
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

	public function testFromRawValueSimple() {
		var raw = [1,2,3];
		var a = @:privateAccess ArrayValue.__fromRawValue(raw, null);
		isTrue(ArrayValue.isArrayValue(a));
		same([1, 2, 3], [for (v in a) v]);
	}

	public function testFromRawValueWithConverter() {
		var raw = ["John", "Mary"];
		var a = @:privateAccess ArrayValue.__fromRawValue(raw, new TestConverter());
		isTrue(ArrayValue.isArrayValue(a));
		equals(2, a.length);
		is(a[0], C);
		equals(a[0].name, "John");
		is(a[1], C);
		equals(a[1].name, "Mary");
	}

	public function testToRawValueSimple() {
		var a = new ArrayValue();
		a.push(1);
		a.push(2);
		a.push(3);
		same([1, 2, 3], @:privateAccess a.__toRawValue());
	}

	public function testToRawValueWithHelper() {
		var a = new ArrayValue();
		@:privateAccess a.__setHelpers(new TestHelper());
		a.push(new C("John"));
		a.push(new C("Mary"));
		same(["John", "Mary"], @:privateAccess a.__toRawValue());
	}

	public function testTransaction() {
		var a = new ArrayValue();
		var t = new Transaction();
		@:privateAccess a.__setup(t, null);

		a.push(1);
		a.push(2);
		t.rollback();
		equals(0, a.length);

		a.push(1);
		t.commit();
		a.pop();
		a.pop();
		t.rollback();
		equals(1, a.length);
		equals(1, a[0]);

		a[0] = 42;
		t.rollback();
		equals(1, a[0]);
	}

	public function testChangesSimple() {
		var a = new ArrayValue();
		var t = new DbChanges();
		@:privateAccess a.__setup(null, t);

		a.push(1);
		a.push(2);

		same([
			DbChange.push([], 1),
			DbChange.push([], 2),
		], t.commit());

		a.pop();
		same([DbChange.pop([])], t.commit());

		a[0] = 42;
		same([DbChange.set(["0"], 42)], t.commit());

		a[0] = 42;
		equals(0, t.commit().length);

		raises(() -> a[-1] = 5);
		raises(() -> a[30] = 5);
	}

	public function testSetupChildren() {
		var a = new ArrayValue();
		@:privateAccess a.__setHelpers(new TestHelper());

		var john = new C("John");
		var mary = new C("Mary");
		a.push(john);
		a.push(mary);

		var t = new Transaction();
		var c = new DbChanges();
		@:privateAccess a.__setup(t, c);

		equals(t, john.t);
		equals(t, mary.t);
		equals(c, john.c);
		equals(c, mary.c);
	}

	public function testChangesValue() {
		var a = new ArrayValue();
		@:privateAccess a.__setHelpers(new TestHelper());
		var t = new DbChanges();
		@:privateAccess a.__setup(null, t);

		var john = new C("John");
		var mary = new C("Mary");

		a.push(john);
		a.push(mary);

		equals(a, john.link.p);
		equals("0", john.link.n);
		equals(a, mary.link.p);
		equals("1", mary.link.n);

		same([
			DbChange.push([], "John"),
			DbChange.push([], "Mary"),
		], t.commit());

		a.pop();
		isNull(mary.link);
		same([DbChange.pop([])], t.commit());

		var dog = new C("Dog");

		a[0] = dog;
		isNull(john.link);
		equals(a, dog.link.p);
		equals("0", dog.link.n);
		same([DbChange.set(["0"], "Dog")], t.commit());

		a[0] = dog;
		equals(0, t.commit().length);
	}
}

private class C {
	public var link:Null<{p:ValueBase, n:String}>;
	public var t:Transaction;
	public var c:DbChanges;

	public var name:String;
	public function new(name) this.name = name;
}

private class TestConverter implements RawValueConverter<C> {
	public function new() {}
	public function fromRawValue(raw:RawValue):C {
		return new C(raw);
	}
}

private class TestHelper implements Helper<C> {
	public function new() {}

	public function link(value:C, parent:ValueBase, name:String):Void {
		value.link = {p: parent, n: name};
	}

	public function unlink(value:C):Void {
		value.link = null;
	}

	public function setup(value:C, transaction:Transaction, dbChanges:DbChanges):Void {
		value.t = transaction;
		value.c = dbChanges;
	}

	@:pure public function toRawValue(value:C):RawValue return value.name;
}

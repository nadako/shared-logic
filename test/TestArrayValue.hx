import utest.Assert.*;
import classy.core.ArrayValue;
import classy.core.Value;
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
}

private class C {
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

	public function link(value:C, parent:ValueBase, name:String):Void {}
	public function unlink(value:C):Void {}
	public function setup(value:C, transaction:Transaction, dbChanges:DbChanges):Void {}
	@:pure public function toRawValue(value:C):RawValue return value.name;
}

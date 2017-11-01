import utest.Assert.*;
import classy.core.ValueBase;

class Some extends ValueBase {
	public function new() {}
}

class TestValueBase {
	public function new() {}

	public function test() {
		var v = new Some();
		var p = new Some();
		@:privateAccess v.__link(p, "some");
		raises(() -> @:privateAccess v.__link(p, "some"));
		same({}, @:privateAccess v.__toRawValue());
	}
}

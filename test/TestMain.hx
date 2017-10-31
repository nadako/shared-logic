import utest.Runner;
import utest.ui.Report;

class TestMain {
	static function main() {
		var cases:Array<Any> = [
			new TestTransaction(),
			new TestDbChanges(),
			new TestValueSimple(),
		];
		var runner = new Runner();
		for (c in cases)
			runner.addCase(c);
		Report.create(runner);
		runner.run();
	}
}

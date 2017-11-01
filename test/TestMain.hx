import utest.Runner;
import utest.ui.Report;

class TestMain {
	static function main() {
		var cases:Array<Any> = [
			new TestTransaction(),
			new TestDbChanges(),
			new TestValueSimple(),
			new TestValueNested(),
			new TestArrayValue(),
		];
		var runner = new Runner();
		for (c in cases)
			runner.addCase(c);
		Report.create(runner).setHandler(function(report) {
			Sys.println(report.getResults());
			#if mcover
			var logger = mcover.coverage.MCoverage.getLogger();
			var client = new mcover.coverage.client.PrintClient();
			client.includeExecutionFrequency = false;
			logger.addClient(client);
			logger.report();
			Sys.println(client.output);
			#end
		});
		runner.run();
	}
}

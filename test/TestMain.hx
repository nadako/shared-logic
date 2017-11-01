import utest.Runner;
import utest.ui.Report;

class TestMain {
	static function main() {
		var cases:Array<Any> = [
			new TestTransaction(),
			new TestDbChanges(),
			new TestValueBase(),
			new TestValueSimple(),
			new TestValueNested(),
			new TestArrayValue(),
			new TestEnumFlat(),
			new TestEnumNested(),
			new TestValueHelper(),
		];
		var runner = new Runner();
		for (c in cases)
			runner.addCase(c);
		Report.create(runner).setHandler(function(report) {
			Sys.println(report.getResults());
			#if mcover
			reportCoverage();
			#end
		});
		runner.run();
	}

	#if mcover
	static function reportCoverage() {
		var logger = mcover.coverage.MCoverage.getLogger();
		var client = new mcover.coverage.client.PrintClient();
		client.includeExecutionFrequency = false;
		client.includePackageBreakdown = false;
		logger.addClient(client);
		logger.report();
		Sys.println(client.output);

		// taken and adapted from https://github.com/HaxeCheckstyle/haxe-checkstyle
		var report:CoverageJson = { coverage: {} };
		var classes = logger.coverage.getClasses();
		for (cls in classes) {
			var coverageData:Array<LineCoverageResult> = [null];
			var results = cls.getResults();
			for (i in 1...results.l) coverageData[i] = 1;

			var missingStatements = cls.getMissingStatements();
			for (stmt in missingStatements) {
				for (line in stmt.lines) coverageData[line] = 0;
			}
			var missingBranches = cls.getMissingBranches();
			for (branch in missingBranches) {
				if (branch.lines.length <= 0) continue;
				var count = 0;
				if (branch.trueCount > 0) count++;
				if (branch.falseCount > 0) count++;
				var line = branch.lines[branch.lines.length - 1];
				coverageData[line] = count + "/2";
			}

			var c = StringTools.replace(cls.name, ".", "/") + ".hx";
			report.coverage[c] = coverageData;
		}
		sys.io.File.saveContent("coverage.json", haxe.Json.stringify(report));
	}
	#end
}

typedef CoverageJson = {
	var coverage:haxe.DynamicAccess<Array<LineCoverageResult>>;
}

typedef LineCoverageResult = Dynamic;

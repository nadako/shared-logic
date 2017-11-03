import utest.Assert.*;
import classy.core.CommandExecutor;

class FlatCommands {
	var result1:String;
	var result2:String;

	public function new() {}

	public function command1() {
		result1 = "command1 done";
	}

	public function command2(arg) {
		result2 = arg;
	}

	function privateMethod() {}
}

class NestedCommands {
	public var sub1:SubCommands;
	public var sub2:SubCommands;
	public function new() {
		sub1 = new SubCommands();
		sub2 = new SubCommands();
	}

	var cmdResult:Int;
	public function cmd(i) cmdResult = i;
}

class SubCommands {
	public var subsub:SubSubCommands;
	public function new() {
		subsub = new SubSubCommands();
	}

	var cmdResult:Int;
	public function cmd(i) cmdResult = i;
}

class SubSubCommands {
	public function new() {}

	var cmdResult:Int;
	public function cmd(i) cmdResult = i;
}

class TestCommandExecutor {
	public function new() {}

	public function testFlat() @:privateAccess {
		var commands = new FlatCommands();
		var executor = new CommandExecutor(commands);
		executor.execute("command1", []);
		equals("command1 done", commands.result1);
		executor.execute("command2", ["hello"]);
		equals("hello", commands.result2);
		raises(() -> executor.execute("privateMethod", []));
		raises(() -> executor.execute("unknownMethod", []));
	}

	public function testNested() @:privateAccess {
		var commands = new NestedCommands();
		var executor = new CommandExecutor(commands);
		executor.execute("cmd", [42]);
		equals(42, commands.cmdResult);
		executor.execute("sub1.cmd", [43]);
		equals(43, commands.sub1.cmdResult);
		executor.execute("sub2.cmd", [44]);
		equals(44, commands.sub2.cmdResult);
		executor.execute("sub1.subsub.cmd", [45]);
		equals(45, commands.sub1.subsub.cmdResult);
		executor.execute("sub2.subsub.cmd", [46]);
		equals(46, commands.sub2.subsub.cmdResult);
	}
}

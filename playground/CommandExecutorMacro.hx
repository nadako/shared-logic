#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

class CommandExecutorMacro {
	static function build() {
		var commandsType = getCommandsType();
		var commandsClass = switch commandsType {
			case TInst(_.get() => cl, _): cl;
			case _: throw "commands type must be a class";
		}
		var executorName = 'CommandExecutor__${commandsClass.name}';
		var dotPath = haxe.macro.MacroStringTools.toDotPath(commandsClass.pack, executorName);
		try Context.getType(dotPath) catch (_:Any) {
			var commandsCT = commandsType.toComplexType();
			var dispatchExpr = generateDispatchExpr(commandsClass, commandsClass.pos);
			var td = macro class $executorName {
				var commands:$commandsCT;
				public function new(commands) this.commands = commands;
				public function execute(name:String, args:Array<Any>) $dispatchExpr;
			}
			Context.defineType(td, commandsClass.module);
		}
		return TPath({pack: commandsClass.pack, name: executorName});
	}

	static function getCommandsType():Type {
		var commandsType = switch Context.getLocalType() {
			case TInst(_, [t]): t;
			case _: throw false; // should not happen
		}

		switch commandsType {
			case TMono(_):
				// we called it as `new CommandExecutor(something)` without specifying the type parameter,
				// which is okay, because we can infer it from the constructor argument
				switch Context.getCallArguments() {
					case [argExpr]:
						commandsType = Context.typeof(argExpr);
					case _:
						throw new Error("CommandExecutor must receive a commands object", Context.currentPos());
				}
			case _:
				// type is known, proceed using it
		}

		return commandsType;
	}

	static function generateDispatchExpr(cl:ClassType, pos:Position) {
		var cases = new Array<Case>();

		function loop(cl:ClassType, nameAcc:Array<String>) {
			for (field in cl.fields.get()) {
				if (!field.isPublic)
					continue;

				var nameAcc = nameAcc.concat([field.name]);
				switch field.type.follow() {
					case TInst(_.get() => cl, _):
						loop(cl, nameAcc);

					case TFun(args, _):
						var args = [for (i in 0...args.length) macro args[$v{i}]];
						var nameExpr = macro $v{nameAcc.join(".")};
						nameAcc.unshift("commands");
						var methodExpr = macro @:privateAccess $p{nameAcc};
						cases.push({
							values: [nameExpr],
							expr: macro $methodExpr($a{args})
						});

					case _:
				}
			}
		}
		loop(cl, []);

		var defaultExpr = macro throw "Unknown command " + name;
		return {pos: pos, expr: ESwitch(macro name, cases, defaultExpr)};
	}
}
#end

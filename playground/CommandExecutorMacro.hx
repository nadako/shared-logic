#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

class CommandExecutorMacro {
	static var id = 0;
	static var cache = new Map<String,String>();

	static function build() {
		var commandsType = getCommandsType();
		var commandsCT = commandsType.toComplexType();
		var key = commandsCT.toString();
		var name = cache[key];
		if (name == null) {
			var id = id++;
			name = "Executor" + id;
			cache[key] = name;
			var dispatchExpr = generateDispatch(commandsType, Context.currentPos());
			var td = macro class $name {
				var commands:$commandsCT;
				public function new(commands) this.commands = commands;
				public function execute(name:String, args:Array<Any>) $dispatchExpr;
			}
			Context.defineType(td);
		}
		return TPath({pack: [], name: name});
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

	static function generateDispatch(type:Type, pos:Position) {
		var cases = new Array<Case>();

		function loop(type:Type, nameAcc:Array<String>) {
			switch type {
				case TInst(_.get() => cl, _):
					for (field in cl.fields.get()) {
						if (!field.isPublic)
							continue;
						var nameAcc = nameAcc.concat([field.name]);
						switch field.type.follow() {
							case TInst(_):
								loop(field.type, nameAcc);
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
				case _:
					throw new Error("commands type is not a class", pos);
			}
		}
		loop(type, []);

		var defaultExpr = macro throw "Unknown command " + name;
		return {pos: pos, expr: ESwitch(macro name, cases, defaultExpr)};
	}
}
#end

package classy.core.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

class HelperGenerator {
	public function new() {
		// TODO: add cache here to prevent stack overflows with recursive types and compiler-cache issues
	}

	public function getHelper(type:Type, realType:Type, pos:Position):HelperInfo {
		switch type {
			case TInst(_.get() => cl, params):
				switch [cl, params] {
					case [{pack: [], name: "String"}, _]:
						return new BasicTypeHelperInfo(true);
					case _ if (isValueClass(cl)):
						return new ValueClassHelperInfo(this, cl, params);
					case _:
				}

			case TAbstract(_.get() => ab, params):
				switch [ab, params] {
					case [{pack: [], name: "Bool" | "Int" | "Float"}, _]:
						return new BasicTypeHelperInfo(false);
					case _ if (!ab.meta.has(":coreType")):
						return getHelper(ab.type.applyTypeParameters(ab.params, params), realType, pos);
					case _:
				}

			case TType(_.get() => dt, params):
				return getHelper(dt.type.applyTypeParameters(dt.params, params), realType, pos);

			case TEnum(_.get() => en, params):
				return new EnumHelperInfo(this, en, params);

			case _:
		}
		throw new Error("Unsupported type for Value fields: " + realType.toString(), pos);
	}

	function isValueClass(cl:ClassType):Bool {
		return switch cl {
			case {pack: ["classy", "core"], name: "ValueBase"}: true;
			case _ if (cl.superClass != null): isValueClass(cl.superClass.t.get());
			case _: false;
		}
	}
}
#end

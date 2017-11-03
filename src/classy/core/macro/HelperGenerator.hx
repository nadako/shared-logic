package classy.core.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.MacroStringTools.toDotPath;
import haxe.macro.Type;
using haxe.macro.Tools;

class HelperGenerator {
	final cache:Map<String,HelperInfo>;
	final defMode:Bool;

	public function new(defMode) {
		this.defMode = defMode; // TODO: rework to baseclass + overrides instead of this flag
		cache = new Map();
	}

	public function getHelper(type:Type, realType:Type, pos:Position):HelperInfo {
		switch type {
			case TInst(_.get() => cl, params):
				var cacheKey = toDotPath(cl.pack, cl.name);
				var info = cache[cacheKey];
				if (info != null) return info;

				switch [cl, params] {
					case [{pack: [], name: "String"}, _]:
						return cache[cacheKey] = new BasicTypeHelperInfo(true);
					case _ if (isValueClass(cl)):
						return cache[cacheKey] = new ValueClassHelperInfo(this, cl, params);
					case _:
				}

			case TAbstract(_.get() => ab, params):
				var cacheKey = toDotPath(ab.pack, ab.name);
				var info = cache[cacheKey];
				if (info != null) return info;

				switch [ab, params] {
					case [{pack: [], name: "Bool" | "Int" | "Float"}, _]:
						return cache[cacheKey] = new BasicTypeHelperInfo(false);
					case _ if (!ab.meta.has(":coreType")):
						return cache[cacheKey] = getHelper(ab.type.applyTypeParameters(ab.params, params), realType, pos);
					case _:
				}

			case TType(_.get() => dt, params):
				var cacheKey = toDotPath(dt.pack, dt.name);
				var info = cache[cacheKey];
				if (info != null) return info;

				return cache[cacheKey] = getHelper(dt.type.applyTypeParameters(dt.params, params), realType, pos);

			case TEnum(_.get() => en, params):
				var cacheKey = toDotPath(en.pack, en.name);
				var info = cache[cacheKey];
				if (info != null) return info;
				var helper = new EnumHelperInfo(this, en, params);
				cache[cacheKey] = helper;
				helper.process();
				return helper;

			case _:
		}
		throw new Error('Unsupported type for ${if (defMode) "Def" else "Value"} fields: ' + realType.toString(), pos);
	}

	function isValueClass(cl:ClassType):Bool {
		return switch cl {
			case {pack: ["classy", "core"], name: "ValueBase"} if (!defMode): true;
			case {pack: ["classy", "core"], name: "Def"} if (defMode): true;
			case _ if (cl.superClass != null): isValueClass(cl.superClass.t.get());
			case _: false;
		}
	}
}
#end

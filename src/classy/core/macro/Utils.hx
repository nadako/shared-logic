package classy.core.macro;

import haxe.macro.Expr;
import haxe.macro.Type;

class Utils {
	public static inline function getRawValueConverterName(name:String)
		return name + "__RawValueConverter";

	public static inline function getHelperName(name:String)
		return name + "__Helper";

	public static function getTypePath(t:BaseType):TypePath {
		var module = t.module.split(".").pop();
		return {
			pack: t.pack,
			name: module,
			sub: t.name
		};
	}
}

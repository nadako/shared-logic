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

	public static function createRawValueConverterClassDefinition(dataTypePath:TypePath, fromRawExpr:Expr):TypeDefinition {
		var dataCT = TPath(dataTypePath);
		var rawValueConverterName = getRawValueConverterName(dataTypePath.sub);
		var rawValueConverterTP = {pack: dataTypePath.pack, name: rawValueConverterName};
		var rawValueConverterTD = macro class $rawValueConverterName implements classy.core.RawValueConverter<$dataCT> {
			inline function new() {}
			static var instance = new $rawValueConverterTP();
			public static inline function get() return instance;
			@:pure public inline function fromRawValue(raw:classy.core.RawValue):$dataCT $fromRawExpr;
		};
		rawValueConverterTD.pack = dataTypePath.pack;
		return rawValueConverterTD;
	}
}

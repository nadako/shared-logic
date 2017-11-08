package classy.core.macro;

import haxe.macro.Expr;

class ValueRawValueConverterBuilder {
	var pos:Position;
	var thisTP:TypePath;
	var thisCT:ComplexType;
	var thisTypeExpr:Expr;
	var fromRawExprs = new Array<Expr>();

	public function new(typePath, pos) {
		this.pos = pos;
		thisTP = typePath;
		thisCT = TPath(typePath);
		thisTypeExpr = macro $p{thisTP.pack.concat([thisTP.name, thisTP.sub])};
	}

	public inline function addFromRawExpr(expr:Expr) {
		fromRawExprs.push(expr);
	}

	public function createFromRawValueField():Field {
		return {
			pos: pos,
			name: "__fromRawValue",
			access: [AStatic],
			meta: [{name: ":pure", pos: pos}],
			kind: FFun({
				args: [{name: "raw", type: macro : classy.core.RawValue}],
				ret: thisCT,
				expr: macro {
					var instance = std.Type.createEmptyInstance($thisTypeExpr);
					$b{fromRawExprs};
					return instance;
				}
			})
		};
	}

	public function createClassDefinition():TypeDefinition {
		var rawValueConverterName = Utils.getRawValueConverterName(thisTP.sub);
		var rawValueConverterTP = {pack: thisTP.pack, name: rawValueConverterName};
		var rawValueConverterTD = macro class $rawValueConverterName implements classy.core.RawValueConverter<$thisCT> {
			inline function new() {}
			static var instance = new $rawValueConverterTP();
			public static inline function get() return instance;
			public inline function fromRawValue(raw) return @:privateAccess $thisTypeExpr.__fromRawValue(raw);
		};
		rawValueConverterTD.pack = thisTP.pack;
		return rawValueConverterTD;
	}
}

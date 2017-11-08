package classy.core.macro;

#if macro
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
		var fromRawMethodExpr = macro return @:privateAccess $thisTypeExpr.__fromRawValue(raw);
		return Utils.createRawValueConverterClassDefinition(thisTP, fromRawMethodExpr);
	}
}
#end
package classy.core.macro;

import haxe.macro.Expr;

class ValueToRawValueBuilder {
	var pos:Position;
	var toRawExprs = new Array<Expr>();

	public function new(pos) {
		this.pos = pos;
	}

	public inline function addToRawExpr(expr:Expr) {
		toRawExprs.push(expr);
	}

	public inline function isNotEmpty() return toRawExprs.length > 0;

	public function createToRawValueField():Field {
		return {
			pos: pos,
			name: "__toRawValue",
			access: [AOverride],
			meta: [{name: ":pure", pos: pos}],
			kind: FFun({
				args: [],
				ret: null,
				expr: macro {
					var raw:classy.core.RawValue = {};
					$b{toRawExprs}
					return raw;
				}
			})
		};
	}
}

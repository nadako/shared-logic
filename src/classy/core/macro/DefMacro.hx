package classy.core.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

import classy.core.macro.Utils.getTypePath;
import classy.core.macro.Utils.getRawValueConverterName;

class DefMacro {
	static var gen = new HelperGenerator(true); // TODO: check how this plays with compiler cache

	static function build() {
		var fields = Context.getBuildFields();
		var newFields = new Array<Field>();
		var toRawExprs = new Array<Expr>();
		var fromRawExprs = new Array<Expr>();

		var thisTP, thisModule, pos;
		switch Context.getLocalType() {
			case TInst(_.get() => cl, _):
				if (cl.isPrivate) throw new Error("Value subclasses cannot be private", cl.pos);
				thisTP = getTypePath(cl);
				thisModule = cl.module;
				pos = cl.pos;
			case _:
				throw new Error("ValueMacro.build() called on a non-class", Context.currentPos());
		}

		var rawValueConverterBuilder = new ValueRawValueConverterBuilder(thisTP, pos);

		for (field in fields) {
			if (field.access.indexOf(AStatic) != -1)
				continue; // skip static fields

			switch field.kind {
				case FFun(_) | FProp("get" | "never", "set" | "never", _, _):
					// allow methods and non-physical properties

				case FProp(_, _, _, _):
					// TODO: look into supporting (some of) these
					throw new Error("Physical properties on Def classes are not supported", field.pos);

				case FVar(type, expr):
					if (expr != null) throw new Error("Def class fields cannot have initializer expressions", expr.pos);
					if (type == null) throw new Error("Def class fields must have explicit type hint", field.pos);

					var fieldName = field.name;
					var fieldType = type.toType();
					var helper = gen.getHelper(fieldType, fieldType, field.pos);

					var toRawExpr = helper.toRaw(macro this.$fieldName, rawValueExpr -> macro raw.$fieldName = $rawValueExpr, () -> macro {});
					toRawExprs.push(toRawExpr);

					var fromRawExpr = helper.fromRaw(macro raw.$fieldName, field.pos);
					rawValueConverterBuilder.addFromRawExpr(macro instance.$fieldName = $fromRawExpr);

					field.kind = FProp("default", "null", type, expr);
			}
		}

		if (toRawExprs.length > 0) {
			newFields.push({
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
			});
		}

		newFields.push(rawValueConverterBuilder.createFromRawValueField());
		Context.defineType(rawValueConverterBuilder.createClassDefinition(), thisModule);

		return fields.concat(newFields);
	}
}
#end

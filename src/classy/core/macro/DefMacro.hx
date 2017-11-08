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
		var ctx = new ValueClassBuildContext();
		var rawValueConverterBuilder = new ValueRawValueConverterBuilder(ctx.typePath, ctx.pos);
		var toRawBuilder = new ValueToRawValueBuilder(ctx.pos);

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
					toRawBuilder.addToRawExpr(toRawExpr);

					var fromRawExpr = helper.fromRaw(macro raw.$fieldName, field.pos);
					rawValueConverterBuilder.addFromRawExpr(macro instance.$fieldName = $fromRawExpr);

					field.kind = FProp("default", "null", type, expr);
			}
		}

		if (toRawBuilder.isNotEmpty())
			newFields.push(toRawBuilder.createToRawValueField());

		newFields.push(rawValueConverterBuilder.createFromRawValueField());
		Context.defineType(rawValueConverterBuilder.createClassDefinition(), ctx.module);

		return fields.concat(newFields);
	}
}
#end

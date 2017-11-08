package classy.core.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

import classy.core.macro.Utils.getTypePath;
import classy.core.macro.Utils.getRawValueConverterName;

class ValueMacro {
	static var gen = new HelperGenerator(false); // TODO: check how this plays with compiler cache

	static function build() {
		var fields = Context.getBuildFields();
		var newFields = new Array<Field>();

		var setupExprs = new Array<Expr>();
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
					throw new Error("Physical properties on Value classes are not supported", field.pos);

				case FVar(type, expr):
					if (type == null) throw new Error("Value class fields must have explicit type hitn", field.pos);

					var fieldName = field.name;
					var fieldType = type.toType();
					var helper = gen.getHelper(fieldType, fieldType, field.pos);

					var setupExpr = helper.setup(macro this.$fieldName, macro transaction, macro dbChanges);
					if (setupExpr != null)
						setupExprs.push(setupExpr);

					var toRawExpr = helper.toRaw(macro this.$fieldName, rawValueExpr -> macro raw.$fieldName = $rawValueExpr, () -> macro {});
					toRawBuilder.addToRawExpr(toRawExpr);

					var fromRawExpr = helper.fromRaw(macro raw.$fieldName, field.pos);
					rawValueConverterBuilder.addFromRawExpr(macro instance.$fieldName = $fromRawExpr);

					var dbChangeExpr = helper.toRaw(
						macro value,
						rawValueExpr -> macro classy.core.DbChange.set(fieldPath, $rawValueExpr),
						() ->  macro classy.core.DbChange.delete(fieldPath)
					);

					field.kind = FProp("default", "set", type, expr);
					newFields.push({
						pos: field.pos,
						name: 'set_$fieldName',
						kind: FFun({
							args: [{name: "value", type: type}],
							ret: type,
							expr: macro {
								var oldValue = this.$fieldName;
								if (oldValue != value) {
									var helper = ${helper.helperExpr()};
									${helper.unlink(macro oldValue)};
									${helper.link(macro value, macro this, macro $v{fieldName}, field.pos)};
									this.$fieldName = value;
									if (__transaction != null)
										__transaction.addRollback(() -> this.$fieldName = oldValue);
									if (__dbChanges != null) {
										var fieldPath = __makeFieldPath([$v{fieldName}]);
										__dbChanges.register($dbChangeExpr);
									}
								}
								return value;
							}
						})
					});
			}
		}

		if (setupExprs.length > 0) {
			newFields.push({
				pos: ctx.pos,
				name: "__setup",
				access: [AOverride],
				kind: FFun({
					args: [
						{name: "transaction", type: null},
						{name: "dbChanges", type: null}
					],
					ret: null,
					expr: macro {
						__transaction = transaction;
						__dbChanges = dbChanges;
						$b{setupExprs}
					}
				})
			});
		}

		if (toRawBuilder.isNotEmpty())
			newFields.push(toRawBuilder.createToRawValueField());

		newFields.push(rawValueConverterBuilder.createFromRawValueField());
		Context.defineType(rawValueConverterBuilder.createClassDefinition(), ctx.module);

		return fields.concat(newFields);
	}
}
#end

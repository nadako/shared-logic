package classy.core.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

class ValueMacro {
	static function build() {
		var fields = Context.getBuildFields();
		var newFields = new Array<Field>();
		var setupExprs = new Array<Expr>();
		var toRawExprs = new Array<Expr>();
		var fromRawExprs = new Array<Expr>();
		var gen = new HelperGenerator();

		var thisTP, thisModule, pos;
		switch Context.getLocalType() {
			case TInst(_.get() => cl, _):
				thisTP = getTypePath(cl);
				thisModule = cl.module;
				pos = cl.pos;
			case _:
				throw new Error("ValueMacro.build() called on a non-class", Context.currentPos());
		}
		var thisCT = TPath(thisTP);

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
					toRawExprs.push(toRawExpr);

					var fromRawExpr = helper.fromRaw(macro raw, macro instance, fieldName, field.pos);
					fromRawExprs.push(fromRawExpr);

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
				pos: pos,
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

		{
			var thisTypeExpr = macro $p{thisTP.pack.concat([thisTP.name, thisTP.sub])};

			newFields.push({
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
			});

			var rawValueConverterName = getRawValueConverterName(thisTP.sub);
			var rawValueConverterTP = {pack: thisTP.pack, name: rawValueConverterName};
			var rawValueConverterTD = macro class $rawValueConverterName implements classy.core.RawValueConverter<$thisCT> {
				inline function new() {}
				static var instance = new $rawValueConverterTP();
				public static inline function get() return instance;
				public inline function fromRawValue(raw) return @:privateAccess $thisTypeExpr.__fromRawValue(raw);
			};
			rawValueConverterTD.pack = thisTP.pack;
			Context.defineType(rawValueConverterTD, thisModule);
		}

		return fields.concat(newFields);
	}

	public static inline function getRawValueConverterName(name:String) return name + "__RawValueConverter";
	public static inline function getHelperName(name:String) return name + "__Helper";

	public static function getTypePath(t:BaseType):TypePath {
		var module = t.module.split(".").pop();
		return {
			pack: t.pack,
			name: module,
			sub: t.name
		};
	}

}
#end

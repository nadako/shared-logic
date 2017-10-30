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
		var pos = Context.currentPos();

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
					var helper = getHelper(fieldType, fieldType, field.pos);

					var setupExpr = helper.setup(macro this.$fieldName, macro transaction, macro dbChanges);
					if (setupExpr != null)
						setupExprs.push(setupExpr);

					var toRawExpr = helper.toRaw(macro this.$fieldName, rawValueExpr -> macro raw.$fieldName = $rawValueExpr, () -> macro {});
					toRawExprs.push(toRawExpr);

					var dbChangeToRawExpr = helper.toRaw(macro value, rawValueExpr -> rawValueExpr, () -> macro null);

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
									${helper.link(macro value, macro this, macro $v{fieldName})};
									this.$fieldName = value;
									if (__transaction != null)
										__transaction.addRollback(() -> this.$fieldName = oldValue);
									if (__dbChanges != null)
										__dbChanges.register({path: __makeFieldPath($v{fieldName}), value: $dbChangeToRawExpr});
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
						var raw:RawValue = {};
						$b{toRawExprs}
						return raw;
					}
				})
			});
		}

		return fields.concat(newFields);
	}

	static function getHelper(type:Type, realType:Type, pos:Position):HelperInfo {
		switch type {
			case TInst(_.get() => cl, params):
				switch [cl, params] {
					case [{pack: [], name: "String"}, _]:
						return new BasicTypeHelperInfo(true);
					case _ if (isValueClass(cl)):
						return new ValueClassHelperInfo();
					case _:
				}

			case TAbstract(_.get() => ab, params):
				switch [ab, params] {
					case [{pack: [], name: "Bool" | "Int" | "Float"}, _]:
						return new BasicTypeHelperInfo(false);
					case _ if (!ab.meta.has(":coreType")):
						return getHelper(ab.type.applyTypeParameters(ab.params, params), realType, pos);
					case _:
				}

			case TType(_.get() => dt, params):
				return getHelper(dt.type.applyTypeParameters(dt.params, params), realType, pos);

			case TEnum(_.get() => en, params):
				throw new Error("Enum on Value classes are not YET supported", pos);

			case _:
		}
		throw new Error("Unsupported type for Value fields: " + realType.toString(), pos);
	}

	static function isValueClass(cl:ClassType):Bool {
		return switch cl {
			case {pack: [], name: "ValueBase"}: true;
			case _ if (cl.superClass != null): isValueClass(cl.superClass.t.get());
			case _: false;
		}
	}
}

private interface HelperInfo {
	function helperExpr():Expr;
	function link(valueExpr:Expr, parentExpr:Expr, nameExpr:Expr):Expr;
	function unlink(valueExpr:Expr):Expr;
	function setup(valueExpr:Expr, transactionExpr:Expr, dbChangesExpr:Expr):Null<Expr>;
	function toRaw(valueExpr:Expr, callback:Expr->Expr, noValueCallback:()->Expr):Expr;
}

private class BasicTypeHelperInfo implements HelperInfo {
	final nullable:Bool;

	public function new(nullable) this.nullable = nullable;

	public function helperExpr():Expr return macro null;
	public function link(valueExpr:Expr, parentExpr:Expr, nameExpr:Expr):Expr return macro {};
	public function unlink(valueExpr:Expr):Expr return macro {};
	public function setup(valueExpr:Expr, transactionExpr:Expr, dbChangesExpr:Expr):Null<Expr> return null;

	public function toRaw(valueExpr:Expr, callback:Expr->Expr, noValueCallback:()->Expr):Expr {
		if (nullable) {
			return macro if ($valueExpr != null) ${callback(valueExpr)} else ${noValueCallback()};
		} else {
			return callback(valueExpr);
		}
	}
}

private class ValueClassHelperInfo implements HelperInfo {
	public function new() {}

	public function helperExpr():Expr {
		return macro null;
	}

	public function link(valueExpr:Expr, parentExpr:Expr, nameExpr:Expr):Expr {
		return macro if ($valueExpr != null) $valueExpr.__link($parentExpr, $nameExpr);
	}

	public function unlink(valueExpr:Expr):Expr {
		return macro if ($valueExpr != null) $valueExpr.__unlink();
	}

	public function setup(valueExpr:Expr, transactionExpr:Expr, dbChangesExpr:Expr):Null<Expr> {
		return macro if ($valueExpr != null) $valueExpr.__setup($transactionExpr, $dbChangesExpr);
	}

	public function toRaw(valueExpr:Expr, callback:Expr->Expr, noValueCallback:()->Expr):Expr {
		return macro if ($valueExpr != null) ${callback(macro $valueExpr.__toRawValue())} else ${noValueCallback()};
	}
}

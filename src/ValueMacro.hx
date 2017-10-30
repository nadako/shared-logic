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

					var fromRawExpr = helper.fromRaw(macro raw, macro instance, fieldName);
					fromRawExprs.push(fromRawExpr);

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

		{
			var thisTypeExpr = macro $p{thisTP.pack.concat([thisTP.name, thisTP.sub])};

			newFields.push({
				pos: pos,
				name: "__fromRawValue",
				access: [AStatic],
				meta: [{name: ":pure", pos: pos}],
				kind: FFun({
					args: [{name: "raw", type: macro : RawValue}],
					ret: thisCT,
					expr: macro {
						var instance = std.Type.createEmptyInstance($thisTypeExpr);
						$b{fromRawExprs};
						return instance;
					}
				})
			});

			var rawValueConverterName = thisTP.sub + "__RawValueConverter";
			var rawValueConverterTD = macro class $rawValueConverterName implements RawValueConverter<$thisCT> {
				public inline function new() {}
				public inline function fromRawValue(raw) return @:privateAccess $thisTypeExpr.__fromRawValue(raw);
			};
			rawValueConverterTD.pack = thisTP.pack;
			Context.defineType(rawValueConverterTD, thisModule);
		}

		return fields.concat(newFields);
	}

	public static function getTypePath(t:BaseType):TypePath {
		var module = t.module.split(".").pop();
		return {
			pack: t.pack,
			name: module,
			sub: t.name
		};
	}

}

private class HelperGenerator {
	public function new() {
		// TODO: add cache here to prevent stack overflows with recursive types and compiler-cache issues
	}

	public function getHelper(type:Type, realType:Type, pos:Position):HelperInfo {
		switch type {
			case TInst(_.get() => cl, params):
				switch [cl, params] {
					case [{pack: [], name: "String"}, _]:
						return new BasicTypeHelperInfo(true);
					case _ if (isValueClass(cl)):
						return new ValueClassHelperInfo(cl);
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

	function isValueClass(cl:ClassType):Bool {
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
	function fromRaw(rawExpr:Expr, instanceExpr:Expr, fieldName:String):Expr;
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

	public function fromRaw(rawExpr:Expr, instanceExpr:Expr, fieldName:String):Expr {
		// TODO: handle weird JS fields like `constructor`
		return macro $instanceExpr.$fieldName = $rawExpr.fieldName;
	}
}

private class ValueClassHelperInfo implements HelperInfo {
	final cl:ClassType;

	public function new(cl) {
		this.cl = cl;
	}

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

	public function fromRaw(rawExpr:Expr, instanceExpr:Expr, fieldName:String):Expr {
		var typeExpr = {
			var a = cl.module.split(".");
			a.push(cl.name);
			macro $p{a};
		};
		return macro $instanceExpr.$fieldName = @:privateAccess $typeExpr.__fromRawValue($rawExpr.$fieldName);
	}
}

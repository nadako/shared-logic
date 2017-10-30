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
						rawValueExpr -> macro DbChanges.DbChange.set(fieldPath, $rawValueExpr),
						() ->  macro DbChanges.DbChange.delete(fieldPath)
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
									${helper.link(macro value, macro this, macro $v{fieldName})};
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

			var rawValueConverterName = getRawValueConverterName(thisTP.sub);
			var rawValueConverterTP = {pack: thisTP.pack, name: rawValueConverterName};
			var rawValueConverterTD = macro class $rawValueConverterName implements RawValueConverter<$thisCT> {
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
						return new ValueClassHelperInfo(this, cl, params);
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
	function rawValueConverterExpr():Expr;
	function link(valueExpr:Expr, parentExpr:Expr, nameExpr:Expr):Expr;
	function unlink(valueExpr:Expr):Expr;
	function setup(valueExpr:Expr, transactionExpr:Expr, dbChangesExpr:Expr):Null<Expr>;
	function toRaw(valueExpr:Expr, callback:Expr->Expr, noValueCallback:()->Expr):Expr;
	function fromRaw(rawExpr:Expr, instanceExpr:Expr, fieldName:String, pos:Position):Expr;
}

private class BasicTypeHelperInfo implements HelperInfo {
	final nullable:Bool;

	public function new(nullable) this.nullable = nullable;

	public function helperExpr():Expr return macro null;
	public function rawValueConverterExpr():Expr return macro null;
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

	public function fromRaw(rawExpr:Expr, instanceExpr:Expr, fieldName:String, pos:Position):Expr {
		// TODO: handle weird JS fields like `constructor`
		return macro $instanceExpr.$fieldName = $rawExpr.$fieldName;
	}
}

private class ValueClassHelperInfo implements HelperInfo {
	final gen:HelperGenerator;
	final classType:ClassType;
	final appliedParams:Array<Type>;

	public function new(gen, classType, appliedParams) {
		this.gen = gen;
		this.classType = classType;
		this.appliedParams = appliedParams;
	}

	public function helperExpr():Expr {
		return macro null;
	}

	public function rawValueConverterExpr():Expr {
		var rawValueConverterName = ValueMacro.getRawValueConverterName(classType.name);
		var typeExpr = macro $p{classType.pack.concat([rawValueConverterName])};
		return macro $typeExpr.get();
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

	function makeTypeExpr() {
		return {
			var a = classType.module.split(".");
			a.push(classType.name);
			macro $p{a};
		};
	}

	public function fromRaw(rawExpr:Expr, instanceExpr:Expr, fieldName:String, pos:Position):Expr {
		var typeExpr = makeTypeExpr();
		var args = [macro $rawExpr.$fieldName];
		for (t in appliedParams) {
			var helper = gen.getHelper(t, t, pos);
			args.push(helper.rawValueConverterExpr());
		}
		return macro $instanceExpr.$fieldName = @:privateAccess $typeExpr.__fromRawValue($a{args});
	}
}

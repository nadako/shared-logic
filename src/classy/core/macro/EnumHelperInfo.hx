package classy.core.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

class EnumHelperInfo implements HelperInfo {
	final gen:HelperGenerator;
	final enumType:EnumType;
	final appliedParams:Array<Type>;
	var _needsLinking:Bool;

	public function new(gen, enumType, appliedParams) {
		this.gen = gen;
		this.enumType = enumType;
		this.appliedParams = appliedParams;
		process();
	}

	function process() {
		var linkCases = new Array<Case>();
		var unlinkCases = new Array<Case>();
		var toRawValueCases = new Array<Case>();
		var fromRawValueCases = new Array<Case>();

		for (ctorName in enumType.names) {
			var ctorField = enumType.constructs[ctorName];
			var ctorIdent = macro $i{ctorName};
			var patternExpr;
			var toRawExpr;
			var fromRawExpr;
			var linkExprs = [];
			var unlinkExprs = [];

			switch ctorField.type {
				case TEnum(_):
					patternExpr = ctorIdent;
					toRawExpr = macro $v{ctorName}; // simple string
					fromRawExpr = ctorIdent;

				case TFun(args, _):
					var ctorArgs = [];
					var toRawExprs = [];
					var fromRawArgExprs = [];
					var objDeclFields = [{field: "$tag", expr: macro $v{ctorName}, quotes: Quoted}];
					for (arg in args) {
						var argName = arg.name;
						var argIdent = macro $i{argName};
						ctorArgs.push(argIdent);
						var argHelper = gen.getHelper(arg.t, arg.t, ctorField.pos);
						if (argHelper.needsLinking()) {
							_needsLinking = true;
							linkExprs.push(argHelper.link(argIdent, macro parent, macro name + $v{"." + argName}, ctorField.pos));
							unlinkExprs.push(argHelper.unlink(argIdent));
						}
						toRawExprs.push(argHelper.toRaw(
							argIdent,
							expr -> macro raw.$argName = $expr,
							() -> macro {}
						));
						fromRawArgExprs.push(argHelper.fromRaw(macro raw.$argName, ctorField.pos));
					}
					patternExpr = macro $ctorIdent($a{ctorArgs});
					toRawExpr = macro {
						var raw:classy.core.RawValue = ${{pos: ctorField.pos, expr: EObjectDecl(objDeclFields)}};
						$b{toRawExprs};
						raw;
					}
					fromRawExpr = macro $ctorIdent($a{fromRawArgExprs});

				case t:
					throw new Error("Unexpected enum field type: " + t.toString(), ctorField.pos);
			}

			linkCases.push({
				values: [patternExpr],
				expr: macro $b{linkExprs}
			});

			unlinkCases.push({
				values: [patternExpr],
				expr: macro $b{unlinkExprs}
			});

			toRawValueCases.push({
				values: [patternExpr],
				expr: toRawExpr
			});

			fromRawValueCases.push({
				values: [macro $v{ctorName}],
				expr: fromRawExpr,
			});
		}

		var linkExpr = if (_needsLinking) {pos: enumType.pos, expr: ESwitch(macro value, linkCases, null)} else macro {};
		var unlinkExpr = if (_needsLinking) {pos: enumType.pos, expr: ESwitch(macro value, unlinkCases, null)} else macro {};

		var enumTP = ValueMacro.getTypePath(enumType);
		var enumCT = TPath(enumTP);

		{
			var helperName = ValueMacro.getHelperName(enumType.name);
			var helperTP = {pack: enumType.pack, name: helperName};
			var helperTD = macro class $helperName implements classy.core.Helper<$enumCT> {
				inline function new() {}
				static var instance = new $helperTP();
				public static inline function get() return instance;

				public function link(value:$enumCT, parent:classy.core.ValueBase, name:String):Void {
					$linkExpr;
				}

				public function unlink(value:$enumCT):Void {
					$unlinkExpr;
				}

				@:pure
				public function toRawValue(value:$enumCT):classy.core.RawValue {
					return ${{pos: enumType.pos, expr: ESwitch(macro value, toRawValueCases, null)}};
				}
			}
			helperTD.pack = enumType.pack;
			Context.defineType(helperTD, enumType.module);
		}

		{
			var rawValueConverterName = ValueMacro.getRawValueConverterName(enumType.name);
			var rawValueConverterTP = {pack: enumType.pack, name: rawValueConverterName};
			var rawValueConverterTD = macro class $rawValueConverterName implements classy.core.RawValueConverter<$enumCT> {
				inline function new() {}
				static var instance = new $rawValueConverterTP();
				public static inline function get() return instance;

				@:pure
				public function fromRawValue(raw:classy.core.RawValue):$enumCT {
					return ${{pos: enumType.pos, expr: ESwitch(macro Reflect.field(raw, "$tag"), fromRawValueCases, macro throw "Unknown enum tag")}};
				}
			}
			rawValueConverterTD.pack = enumType.pack;
			Context.defineType(rawValueConverterTD, enumType.module);
		}

		_needsLinking = true;
	}

	public function needsLinking():Bool {
		return _needsLinking;
	}

	public function helperExpr():Expr {
		var helperName = ValueMacro.getHelperName(enumType.name);
		var typeExpr = macro $p{enumType.pack.concat([helperName])};
		return macro $typeExpr.get();
	}

	public function rawValueConverterExpr():Expr {
		var rawValueConverterName = ValueMacro.getRawValueConverterName(enumType.name);
		var typeExpr = macro $p{enumType.pack.concat([rawValueConverterName])};
		return macro $typeExpr.get();
	}

	public function link(valueExpr:Expr, parentExpr:Expr, nameExpr:Expr, pos:Position):Expr {
		return macro if ($valueExpr != null) ${helperExpr()}.link($valueExpr, $parentExpr, $nameExpr);
	}

	public function unlink(valueExpr:Expr):Expr {
		return macro if ($valueExpr != null) ${helperExpr()}.unlink($valueExpr);
	}

	public function setup(valueExpr:Expr, transactionExpr:Expr, dbChangesExpr:Expr):Null<Expr> {
		return macro if ($valueExpr != null) $valueExpr/* .__setup($transactionExpr, $dbChangesExpr) */;
	}

	public function toRaw(valueExpr:Expr, callback:Expr->Expr, noValueCallback:()->Expr):Expr {
		return macro if ($valueExpr != null) ${callback(macro ${helperExpr()}.toRawValue($valueExpr))} else ${noValueCallback()};
	}

	function makeTypeExpr() {
		return {
			var a = enumType.module.split(".");
			a.push(enumType.name);
			macro $p{a};
		};
	}

	public function fromRaw(rawExpr:Expr, pos:Position):Expr {
		return macro ${rawValueConverterExpr()}.fromRawValue($rawExpr);
	}
}
#end

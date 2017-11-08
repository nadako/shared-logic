package classy.core.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

import classy.core.macro.Utils.getRawValueConverterName;

class ValueClassHelperInfo implements HelperInfo {
	final gen:HelperGenerator;
	final classType:ClassType;
	final appliedParams:Array<Type>;

	public function new(gen, classType, appliedParams) {
		this.gen = gen;
		this.classType = classType;
		this.appliedParams = appliedParams;
	}

	public function needsLinking():Bool {
		return true;
	}

	public function helperExpr():Expr {
		return macro classy.core.ValueHelper.get();
	}

	public function rawValueConverterExpr():Expr {
		var rawValueConverterName = getRawValueConverterName(classType.name);
		var typeExpr = macro $p{classType.pack.concat([rawValueConverterName])};
		return macro $typeExpr.get();
	}

	public function link(valueExpr:Expr, parentExpr:Expr, nameExpr:Expr, pos:Position):Expr {
		var linkExpr = macro @:privateAccess $valueExpr.__link($parentExpr, $nameExpr);
		if (appliedParams.length > 0) {
			var helperExprs = [];
			iterTypeParams(function(t) {
				var helper = gen.getHelper(t, t, pos);
				helperExprs.push(helper.helperExpr());
			});
			linkExpr = macro {
				@:privateAccess $valueExpr.__setHelpers($a{helperExprs});
				$linkExpr;
			}
		}

		return macro if ($valueExpr != null) $linkExpr;
	}

	public function unlink(valueExpr:Expr):Expr {
		return macro if ($valueExpr != null) @:privateAccess $valueExpr.__unlink();
	}

	public function setup(valueExpr:Expr, transactionExpr:Expr, dbChangesExpr:Expr):Null<Expr> {
		return macro if ($valueExpr != null) @:privateAccess $valueExpr.__setup($transactionExpr, $dbChangesExpr);
	}

	public function toRaw(valueExpr:Expr, callback:Expr->Expr, noValueCallback:()->Expr):Expr {
		return macro if ($valueExpr != null) ${callback(macro @:privateAccess $valueExpr.__toRawValue())} else ${noValueCallback()};
	}

	function makeTypeExpr() {
		return {
			var a = classType.module.split(".");
			a.push(classType.name);
			macro $p{a};
		};
	}

	function iterTypeParams(f:Type->Void) {
		for (i in 0...classType.params.length) {
			var skip = switch classType.params[i].t { case TInst(_.get() => c, _): c.meta.has(":basic"); case _: throw false; };
			if (!skip)
				f(appliedParams[i]);
		}
	}

	public function fromRaw(rawExpr:Expr, pos:Position):Expr {
		var typeExpr = makeTypeExpr();
		var args = [macro $rawExpr];
		iterTypeParams(function(t) {
			var helper = gen.getHelper(t, t, pos);
			args.push(helper.rawValueConverterExpr());
		});
		return macro if ($rawExpr == null) null else @:privateAccess $typeExpr.__fromRawValue($a{args});
	}
}
#end

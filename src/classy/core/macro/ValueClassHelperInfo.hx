package classy.core.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

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
		var rawValueConverterName = ValueMacro.getRawValueConverterName(classType.name);
		var typeExpr = macro $p{classType.pack.concat([rawValueConverterName])};
		return macro $typeExpr.get();
	}

	public function link(valueExpr:Expr, parentExpr:Expr, nameExpr:Expr, pos:Position):Expr {
		var linkExpr = macro @:privateAccess $valueExpr.__link($parentExpr, $nameExpr);

		if (appliedParams.length > 0) {
			var helperExprs = [];
			for (t in appliedParams) {
				var helper = gen.getHelper(t, t, pos);
				helperExprs.push(helper.helperExpr());
			}
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
		return macro if ($valueExpr != null) $valueExpr.__setup($transactionExpr, $dbChangesExpr);
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

	public function fromRaw(rawExpr:Expr, pos:Position):Expr {
		var typeExpr = makeTypeExpr();
		var args = [macro $rawExpr];
		for (t in appliedParams) {
			var helper = gen.getHelper(t, t, pos);
			args.push(helper.rawValueConverterExpr());
		}
		return macro @:privateAccess $typeExpr.__fromRawValue($a{args});
	}
}
#end

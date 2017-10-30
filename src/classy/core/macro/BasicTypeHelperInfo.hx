package classy.core.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;

class BasicTypeHelperInfo implements HelperInfo {
	final nullable:Bool;

	public function new(nullable) this.nullable = nullable;

	public function helperExpr():Expr return macro null;
	public function rawValueConverterExpr():Expr return macro null;
	public function link(valueExpr:Expr, parentExpr:Expr, nameExpr:Expr, pos:Position):Expr return macro {};
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
#end

package classy.core.macro;

import haxe.macro.Expr;

interface HelperInfo {
	function helperExpr():Expr;
	function rawValueConverterExpr():Expr;
	function link(valueExpr:Expr, parentExpr:Expr, nameExpr:Expr, pos:Position):Expr;
	function unlink(valueExpr:Expr):Expr;
	function setup(valueExpr:Expr, transactionExpr:Expr, dbChangesExpr:Expr):Null<Expr>;
	function toRaw(valueExpr:Expr, callback:Expr->Expr, noValueCallback:()->Expr):Expr;
	function fromRaw(rawExpr:Expr, instanceExpr:Expr, fieldName:String, pos:Position):Expr;
}

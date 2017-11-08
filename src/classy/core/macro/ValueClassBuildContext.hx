package classy.core.macro;

import haxe.macro.Context;
import haxe.macro.Expr;

class ValueClassBuildContext {
	public final typePath:TypePath;
	public final module:String;
	public final pos:Position;

	public function new() {
		switch Context.getLocalType() {
			case TInst(_.get() => cl, _):
				if (cl.isPrivate) // TODO: probably can be supported
					throw new Error("Data classes cannot be private", cl.pos);
				typePath = Utils.getTypePath(cl);
				module = cl.module;
				pos = cl.pos;
			case _:
				// this should not happen, but if anyone misuse this macro they will see a nice error
				throw new Error("Data class build macro called on a non-class", Context.currentPos());
		}
	}
}

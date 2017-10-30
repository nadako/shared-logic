class ValueBase {
	var __parent:ValueBase;
	var __name:String;
	var __transaction:Transaction;
	var __dbChanges:DbChanges;

	function __link(parent:ValueBase, name:String) {
		if (__parent != null) throw "Object is already linked";
		__parent = parent;
		__name = name;
		__setup(__parent.__transaction, __parent.__dbChanges);
	}

	function __unlink() {
		__parent = null;
		__name = null;
	}

	function __setup(transaction:Transaction, dbChanges:DbChanges) {
		__transaction = transaction;
		__dbChanges = dbChanges;
	}

	@:pure
	function __toRawValue():RawValue {
		return {};
	}

	@:pure
	function __makeFieldPath(field:String):Array<String> {
		var path = [field];
		var object = this;
		while (object.__parent != null) {
			path.push(object.__name);
			object = object.__parent;
		}
		path.reverse();
		return path;
	}
}

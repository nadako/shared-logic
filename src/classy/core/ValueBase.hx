package classy.core;

/**
	Базовый класс для всех классов модели.
	Имеет два типа наследников:
	 - Value - магический класс для пользовательских структур
	 - Коллекции (напр. ArrayValue), реализованные вручную
**/
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
		__dbChanges = null;
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
	function __makeFieldPath(path:Array<String>):Array<String> {
		var object = this;
		while (object.__parent != null) {

			// в случае Value-объектов внутри enum, их путь будет закодирован через точку
			// так что сканим строку на предмет частей разделенных точкой и добавляем их в путь
			var name = object.__name;
			var end = name.length, i = name.length;
			while (i-- > 0) {
				if (StringTools.fastCodeAt(name, i) == ".".code) {
					path.push(name.substring(i + 1, end));
					end = i;
				}
			}
			path.push(name.substring(0, end));

			object = object.__parent;
		}
		path.reverse();
		return path;
	}
}

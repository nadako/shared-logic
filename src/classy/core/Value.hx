package classy.core;

/**
	Базовый класс для пользовательских структур.
	Реализует весь бойлерплейт для (де)сериализации и сеттеров.
**/
@:autoBuild(classy.core.macro.ValueMacro.build())
class Value extends ValueBase {}

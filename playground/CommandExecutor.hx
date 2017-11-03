/**
	Класс, отвечающий за диспетчеризацию команд.

	Инициализируется классом с методами-командами, принимает имя и аргументы команды и
	выполняет соотвествующую функцию.

	Методы описанные здесь приведены лишь для само-документации и поддержки автодополнения в редакторах.
	Реальный класс с реализацией execute будет сгенерирован для конкретного класса команд T
	через механизм @:genericBuild (https://haxe.org/manual/macro-generic-build.html).

	Все публичные функции класса T станут доступны как команды для выполнения. Кроме того, все публичные
	поля, хранящие ссылки на другие классы будут рекурсивно обработаны и их методы будут так же доступны как команды.

	Пример:

	class Commands {
		public var sub:SubCommands;

		public function new() {
			sub = new SubCommands();
		}

		public function doStuff() {}
	}

	class SubCommands {
		public function new() {}

		public function doOtherStuff() {}
	}

	var executor = new CommandExecutor(new Commands());
	executor.execute("doStuff", []);
	executor.execute("sub.doOtherStuff", []);
**/
#if !display @:genericBuild(CommandExecutorMacro.build()) #end
class CommandExecutor<T> {
	public function new(commands:T) {}
	public function execute(name:String, args:Array<Any>) {}
}

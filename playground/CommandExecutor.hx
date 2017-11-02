@:genericBuild(CommandExecutorMacro.build())
class CommandExecutor<T> {
	// these will be generated
	public function new(commands:T) {}
	public function execute(name:String, args:Array<Any>) {}
}

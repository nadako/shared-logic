class Context {
	public var data(default,null):GameData;
	public var commandTime(default,null):Time;

	public function new() {}

	@:allow(Logic)
	inline function setup(data) this.data = data;

	@:allow(Logic)
	inline function setCommandTime(time) this.commandTime = time;
}

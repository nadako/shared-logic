class Context {
	public var data(default,null):GameData;
	public var defs(default,null):DefData;
	public var commandTime(default,null):Time;

	public function new() {}

	@:allow(Logic)
	inline function setup(data, defs) {
		this.data = data;
		this.defs = defs;
	}

	@:allow(Logic)
	inline function setCommandTime(time) this.commandTime = time;
}

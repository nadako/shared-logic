var logicModule = require("./bin/logic.js");
var logic = new logicModule.Logic();

var data = {
	counter: 0,
	player: {
		name: "Some guy"
	}
}

var defs = {
	increaseValue: 100,
}

logic.setup(data, defs);

var changes = logic.execute(100600, "increaseCounter", []);
for (change of changes) {
	console.log(`Got change ${JSON.stringify(change)}`);
}

var changes = logic.execute(100500, "player.changeName", ["Other guy"]);
for (change of changes) {
	console.log(`Got change ${JSON.stringify(change)}`);
}

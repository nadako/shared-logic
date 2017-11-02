var logicModule = require("./bin/logic.js");
var logic = new logicModule.Logic();

var data = {
	player: {
		name: "Some guy"
	}
}

logic.setup(data);
var changes = logic.execute(100500, "changeName", ["Other guy"]);

for (change of changes) {
	console.log(`Got change ${JSON.stringify(change)}`);
}

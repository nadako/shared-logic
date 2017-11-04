var logicModule = require("./bin/logic.js");
var logic = new logicModule.Logic();

var data = {
	counter: 0,
	player: {
		name: "Some guy",
		gender: "Male",
		inventory: [
			"LotteryTicket",
			{"$tag": "HeroParts", "heroId": "antonia", "amount": 3},
			{"$tag": "Chest", "chestId": "woodenChest"},
		]
	}
}

var defs = {
	increaseValue: 100,
	limits: {
		counterLimit: 150
	}
}

logic.setup(data, defs);

var changes = logic.execute(100600, "increaseCounter", []);
for (change of changes) {
	console.log(`Got change ${JSON.stringify(change)}`);
}

var changes = logic.execute(100600, "increaseCounter", []);
for (change of changes) {
	console.log(`Got change ${JSON.stringify(change)}`);
}

var changes = logic.execute(100500, "player.changeName", ["Other guy"]);
for (change of changes) {
	console.log(`Got change ${JSON.stringify(change)}`);
}

logic.execute(100700, "player.checkInventory", []);
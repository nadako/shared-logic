var logicModule = require("./bin/logic.js");
var logic = new logicModule.Logic();

var data = {
	counter: 0,
	heroes: {

	},
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

function exec(time, name, args) {
	var changes = logic.execute(time, name, args);
	for (change of changes) {
		console.log(`Got change ${JSON.stringify(change)}`);
	}
}

exec(100600, "increaseCounter", []);
exec(100600, "increaseCounter", []);
exec(100500, "player.changeName", ["Other guy"]);
exec(100700, "player.checkInventory", []);
exec(100800, "player.addHero", ["arnie"]);
exec(100800, "player.addHero", ["arnie"]);
exec(100800, "player.removeHeroes", ["arnie"]);

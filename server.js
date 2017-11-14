var logicModule = require("./bin/logic.js");

var data = {
	"exp": 0,
	"gold": 100,
	"premium": false,
	"heroes": {
		"nextId": 3,
		"data": {
			"1": {
				"type": "rambo",
				"level": 0
			},
			"2": {
				"type": "pony",
				"level": 3
			}
		}
	}
}

var defs = {
	"clickExp": 10,
	"clickRewards": [
		{
			"exp": 10,
			"reward": "PremiumStatus"
		},
		{
			"exp": 20,
			"reward": {"$tag": "Gold", "amount": 1000}
		},
		{
			"exp": 30,
			"reward": {"$tag": "Hero", "type": "rambo", "level": 3}
		}
	]
}

var data = logicModule.convertData(data);
var defs = logicModule.convertDefs(defs);

var logic = new logicModule.Logic();
logic.setup(data, defs);

function exec(time, name, args) {
	var changes = logic.execute(time, name, args);
	for (change of changes) {
		console.log(`Got change ${JSON.stringify(change)}`);
	}
}

exec(0, "click", []);
exec(10, "click", []);
exec(20, "click", []);

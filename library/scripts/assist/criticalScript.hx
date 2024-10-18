var enabled = self.makeBool(false);


var critical_moves = ["strong_forward_attack", "strong_up_attack", "strong_down_attack"];
function willCrit() {
	return Random.getInt(1, 20) <= 3;
}

function isRunning() {
	var objs: Array<CustomGameObject> = match.getCustomGameObjects();
	var foundExisting = false;
	Engine.forEach(objs, function (obj: CustomGameObject, _idx: Int) {
		if (obj.exports.specialModesCritical == true) {
			foundExisting = true;
			return false;
		} else {
			return true;
		}
	}, []);
	Engine.log(foundExisting);
	return foundExisting;


}

function createController() {
	if (!isRunning()) {
		Engine.log("creating controller");
		var player: Character = self.getOwner();
		var resource: String = player.getAssistContentStat("spriteContent") + "controller";
		var controller: CustomApiObject = match.createCustomGameObject(resource, player);
		controller.exports.specialModesCritical = true;
	}
}

function visuals(event: GameObjectEvent) {
	var foe: Character = event.data.foe;


	camera.addForcedTarget(foe);
	camera.setMode(1);
	event.data.self.addTimer(15, 1, function () {
		camera.deleteForcedTarget(foe);
		camera.addTarget(foe);
		camera.setMode(0);
	}, { persistent: true });
}

function boostStats(event: GameObjectEvent) {

	event.data.hitboxStats.hitstopOffset = 15;
	event.data.hitboxStats.selfHitstopOffset = 15;
	event.data.hitboxStats.damage = event.data.hitboxStats.damage * 1.7;
	event.data.hitboxStats.knockbackGrowth = event.data.hitboxStats.knockbackGrowth + 10;
}


/** 
 * Checks if any item in the array is either equal to or is a subtring of the target
 * @param {String[]} arr - array of strings
 * @param {String} target - target string
 */
function containsString(arr: Array<String>, item: String) {
	for (i in arr) {
		if (i == item) {
			return true;
		}
	}
	return false;
}


function enableCriticalMode() {
	var players = match.getPlayers();
	if (!isRunning()) {
		Engine.forEach(players, function (player: Character, _idx: Int) {
			player.addTimer(1, -1,
				function () {
					var firstFrame = player.getCurrentFrame() <= 2;
					if (willCrit() && firstFrame) {
						player.addEventListener(GameObjectEvent.HIT_DEALT, visuals);
						player.addEventListener(GameObjectEvent.HITBOX_CONNECTED, boostStats);

					}
				}
				, { persistent: true });
			return true;
		}, []);
	}
	var player: Character = self.getOwner();
	var container: Container = player.getDamageCounterContainer();
	var resource: String = player.getAssistContentStat("spriteContent") + "critical";
	var sprite = Sprite.create(resource);
	sprite.scaleY = 0.6;
	sprite.scaleX = 0.6;
	sprite.y = sprite.y + 12;
	sprite.x = sprite.x + (8 * 13);
	container.addChild(sprite);
	createController();


}

// Runs on object init
function initialize() {
}

function update() {
	var player: Character = self.getOwner();
	player.setAssistCharge(0);
	if (match.getPlayers().length > 1 && !enabled.get()) {
		var port = player.getPlayerConfig().port;
		Engine.log("Player " + port);
		enabled.set(true);
		player.addTimer((1 + port) * 5, 1, function () {
			enableCriticalMode();
		}, { persistent: true });
	}
}
// function onTeardown() {
// }

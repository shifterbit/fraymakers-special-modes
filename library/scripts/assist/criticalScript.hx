var enabled = self.makeBool(false);


var critical_moves = ["strong_forward_attack", "strong_up_attack", "strong_down_attack"];
function willCrit() {
	return Random.getInt(1, 16) == 8;
}

function visuals(event: GameObjectEvent) {
	Engine.log("running visuals");
	var foe: Character = event.data.foe;
	var darken = new HsbcColorFilter();
	darken.brightness = 0.1;
	darken.saturation = 0;


	camera.addForcedTarget(foe);
	camera.setMode(1);
	event.data.self.addTimer(15, 1, function () {
		camera.deleteForcedTarget(foe);
		camera.addTarget(foe);
		camera.setMode(0);
	}, {});
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


function enableDramaticMode() {
	var players = match.getPlayers();
	Engine.log(players);
	Engine.forEach(players, function (player: Character, _idx: Int) {
		Engine.log(player);
		player.addTimer(1, -1,
			function () {
				var firstFrame = player.getCurrentFrame() <= 3;
				if (willCrit()) {
					player.addEventListener(GameObjectEvent.HIT_DEALT, visuals);
					player.addEventListener(GameObjectEvent.HITBOX_CONNECTED, boostStats);

				}
			}
			, { persistent: true });
		return true;
	}, []);

}

// Runs on object init
function initialize() {
}

function update() {
	var player: Character = self.getOwner();
	player.setAssistCharge(0);
	if (match.getPlayers().length > 1 && !enabled.get()) {
		enabled.set(true);
		enableDramaticMode();
	}
}
// function onTeardown() {
// }

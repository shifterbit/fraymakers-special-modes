var enabled = self.makeBool(false);


function isRunning() {
    var objs: Array<CustomGameObject> = match.getCustomGameObjects();
    var foundExisting = false;
    Engine.forEach(objs, function (obj: CustomGameObject, _idx: Int) {
        if (obj.exports.specialModesDramatic == true) {
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
        controller.exports.specialModesDramatic = true;
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

function enableDramaticMode() {
    var players = match.getPlayers();
    if (!isRunning()) {
        Engine.forEach(players, function (player: Character, _idx: Int) {
            player.addTimer(1, -1,
                function () {
                    player.addEventListener(GameObjectEvent.HIT_DEALT, visuals, { persistent: true });
                }
                , { persistent: true });
            return true;
        }, []);
    }
    var player: Character = self.getOwner();
    var container: Container = player.getDamageCounterContainer();
    var resource: String = player.getAssistContentStat("spriteContent") + "dramatic";
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
            enableDramaticMode();
        }, { persistent: true });
    }
}
// function onTeardown() {
// }

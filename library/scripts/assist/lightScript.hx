var enabled = self.makeBool(false);

function isRunning() {
    var objs: Array<CustomGameObject> = match.getCustomGameObjects();
    var foundExisting = false;
    Engine.forEach(objs, function (obj: CustomGameObject, _idx: Int) {
        if (obj.exports.specialModesLight == true) {
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
        controller.exports.specialModesLight = true;
    }
}

function enableLightMode() {
    if (!isRunning) {
        Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
            return true;
        }, []);
    }
    var player: Character = self.getOwner();
    var container: Container = player.getDamageCounterContainer();
    var resource: String = player.getAssistContentStat("spriteContent") + "light";
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
            enableLightMode();
        }, { persistent: true });
    }
}
function onTeardown() {
}
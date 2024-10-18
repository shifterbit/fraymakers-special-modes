var enabled = self.makeBool(false);

function isRunning() {
    var objs: Array<CustomGameObject> = match.getCustomGameObjects();
    var foundExisting = false;
    Engine.forEach(objs, function (obj: CustomGameObject, _idx: Int) {
        if (obj.exports.specialModesVengeance == true) {
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
        controller.exports.specialModesVengeance = true;
    }
}
function vengeance(event: GameObjectEvent) {
    event.data.self.addDamage(Math.ceil(event.data.hitboxStats.damage / 2));

}

function enableVengeanceMode() {
    if (!isRunning()) {
        var players = match.getPlayers();
        Engine.forEach(players, function (player: Character, _idx: Int) {
            player.addEventListener(GameObjectEvent.HIT_DEALT, vengeance, { persistent: true });
            return true;
        }, []);
    }
    var player: Character = self.getOwner();
    var container: Container = player.getDamageCounterContainer();
    var resource: String = player.getAssistContentStat("spriteContent") + "vengeance";
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
            enableVengeanceMode();
        }, { persistent: true });
    }
}
function onTeardown() {
}

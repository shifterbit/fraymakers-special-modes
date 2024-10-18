var enabled = self.makeBool(false);


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


function isRunning() {
    var objs: Array<CustomGameObject> = match.getCustomGameObjects();
    var foundExisting = false;
    Engine.forEach(objs, function (obj: CustomGameObject, _idx: Int) {
        if (obj.exports.specialModesSmash64 == true) {
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
        controller.exports.specialModesSmash64 = true;
    }
}
function smash64Mode(obj: Character) {
    obj.addStatusEffect(StatusEffectType.ATTACK_HITSTUN_MULTIPLIER, 1.4);
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.SPECIAL_SIDE);
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.THROW_DOWN);
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.THROW_UP);
    obj.updateCharacterStats({ airdashLimit: 0 });


    obj.addTimer(1, -1, function () {
        if (obj.inState(CState.SPOT_DODGE)) {
            obj.endAnimation();
            obj.toState(CState.SHIELD_LOOP);
        }
    }, { persistent: true });

    obj.addEventListener(GameObjectEvent.HITBOX_CONNECTED, function (event: GameObjectEvent) {
        event.data.hitboxStats.directionalInfluence = false;
    }, { persistent: true });
}

function enableSmash64() {
    if (!isRunning()) {
        Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
            smash64Mode(player);
            return true;
        }, []);
    }
    var player: Character = self.getOwner();
    var container: Container = player.getDamageCounterContainer();
    var resource: String = player.getAssistContentStat("spriteContent") + "smash64";
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
            enableSmash64();
        }, { persistent: true });
    }
}
function onTeardown() {
}

var enabled = self.makeBool(false);

function isRunning() {
    var objs: Array<CustomGameObject> = match.getCustomGameObjects();
    var foundExisting = false;
    Engine.forEach(objs, function (obj: CustomGameObject, _idx: Int) {
        if (obj.exports.specialModesSSF1 == true) {
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
        controller.exports.specialModesSSF1 = true;
    }
}


function ssf1Mode(obj: Character) {
    obj.addStatusEffect(StatusEffectType.GROUND_FRICTION_MULTIPLIER, 0.3);
    obj.addStatusEffect(StatusEffectType.AERIAL_FRICTION_MULTIPLIER, 0.07);
    obj.addStatusEffect(StatusEffectType.ATTACK_HITSTOP_MULTIPLIER, 0);
    // obj.addStatusEffect(StatusEffectType.ATTACK_HITSTUN_MULTIPLIER, 0);

    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_UP);
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_FORWARD);
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_DOWN);

    obj.updateCharacterStats({ airdashLimit: 0 });

    obj.addTimer(2, -1, function () {
        obj.reactivateHitboxes();

    }, { persistent: true });
    obj.addEventListener(GameObjectEvent.HITBOX_CONNECTED, function (event: GameObjectEvent) {
        event.data.hitboxStats.hitEffectOverride = "";
    }, { persistent: true });
    obj.addTimer(0.5, -1, function () {
        obj.setAirdashCount(0);
        var grounded = obj.isOnFloor();
        if (false
            || obj.inStateGroup(CStateGroup.AIRDASH)
            || obj.inStateGroup(CStateGroup.GRAB)
            || obj.inStateGroup(CStateGroup.SHIELD)) {
            obj.endAnimation();

        }
        var pressingRight = obj.getHeldControls().RIGHT;
        var pressingLeft = obj.getHeldControls().LEFT;
        if ((obj.isFacingLeft() && pressingRight) || (obj.isFacingRight() && pressingLeft)) {
            obj.flipX(obj.getX());
            if (obj.isFacingLeft()) {
                obj.faceRight();
            } else if (obj.isFacingRight()) {
                obj.faceLeft();
            }
            if (grounded) {
                obj.resetMomentum();
                if (obj.inStateGroup(CStateGroup.WALK)) {
                    obj.toState(CState.WALK_LOOP);
                } else if (obj.getState() == CState.RUN || obj.getState() == CState.DASH) {
                    obj.toState(CState.DASH);
                } else {
                    obj.endAnimation();
                    obj.toState(CState.WALK_LOOP);

                }
                //obj.setXVelocity(-obj.getXVelocity());
            } else {
                obj.toState(CState.FALL);
            }

        }

        if (obj.getState() == CState.SHIELD_LOOP || obj.getState() == CState.SHIELD_IN || obj.getState() == CState.SHIELD_OUT) {
            obj.getState(CState.STAND);
        }

    }, { persistent: true });

}

function enableSSF1Mode() {
    if (!isRunning()) {
        Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
            ssf1Mode(player);
            return true;
        }, []);
        Engine.forEach(match.getStructures(), function (structure: Structure, _idx: Int) {
            structure.updateStructureStats({ leftLedge: false, rightLedge: false });
            return true;
        }, []);
    }
    var player: Character = self.getOwner();
    var container: Container = player.getDamageCounterContainer();
    var resource: String = player.getAssistContentStat("spriteContent") + "ssf1";
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
            enableSSF1Mode();
        }, { persistent: true });
    }
}
function onTeardown() {
}

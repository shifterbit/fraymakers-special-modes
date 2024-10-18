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


function exMode(obj: Character) {
    obj.addEventListener(GameObjectEvent.HIT_DEALT, function (event: GameObjectEvent) {
        var player: Character = event.data.self;
        var cancelWindow = event.data.hitboxStats.hitstop + 10;
        var airborne = !player.isOnFloor();
        if (airborne) {
            player.preLand(true);
        }
        var performedCancel = false;
        player.updateCharacterStats({grabAirType: GrabAirType.GRAB});
        player.addTimer(1, cancelWindow, function () {
            
            var currentAnimation = player.getAnimation();
            var usingSpecial = currentAnimation.substr(0, 7) == "special";
            var heldControls = player.getHeldControls();
            var side = heldControls.LEFT || heldControls.RIGHT;
            var up = heldControls.UP;
            var down = heldControls.DOWN;
            var neutral = !(up || down || side);
            var special = heldControls.SPECIAL;
            var jump = heldControls.JUMP_ANY || heldControls.JUMP || heldControls.TAP_JUMP;
            var grab = heldControls.GRAB;
            var clutch = heldControls.SHIELD2;
            
            var normal = heldControls.ATTACK;
            if (!usingSpecial) {
                if (special && side && airborne) {
                    player.playAnimation("special_side_air");
                } else if (special && side) {
                    player.playAnimation("special_up");
                } else if (special && up && airborne) {
                    player.playAnimation("special_up_air");
                } else if (special && up) {
                    player.playAnimation("special_up");
                } else if (special && down && airborne) {
                    player.playAnimation("special_down_air");
                } else if (special && down) {
                    player.playAnimation("special_down");
                } else if (special && neutral && airborne) {
                    player.playAnimation("special_neutral_air");
                } else if (special && neutral) {
                    player.playAnimation("special_neutral");
                }
                performedCancel = true;
            } else {
                if (jump && airborne) {
                    obj.setState(CState.JUMP_MIDAIR);
                } else if (jump && !airborne) {
                    obj.setState(CState.JUMP_IN);
                }

            }

        }, { persistent: true });
    }, { persistent: true });


}

function enableEXMode() {
    Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
        exMode(player);
        return true;
    }, []);
    var player: Character = self.getOwner();
    var container: Container = player.getDamageCounterContainer();
    var resource: String = player.getAssistContentStat("spriteContent") + "exmode";
    var sprite = Sprite.create(resource);
    sprite.scaleY = 0.6;
    sprite.scaleX = 0.6;
    sprite.y = sprite.y + 12;
    sprite.x = sprite.x + (8 * 13);
    container.addChild(sprite);
}

// Runs on object init
function initialize() {
}

function update() {
    var player: Character = self.getOwner();
    player.setAssistCharge(0);
    if (match.getPlayers().length > 1 && !enabled.get()) {
        enabled.set(true);
        enableEXMode();
    }
}
function onTeardown() {
}

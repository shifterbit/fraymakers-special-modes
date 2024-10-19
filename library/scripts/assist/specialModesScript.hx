// Runs on object init

// DO NOT TOUCH
var enabled = self.makeBool(false);
var prefix = "specialModeType_";
var mode = "none";
var modes = [
    "none",
    "mega",
    "mini",
    "heavy",
    "light",
    "smash64",
    "vampire",
    "vengeance",
    "turbo",
    "dramatic",
    "critical",
    "ssf1",
    "exmode"
];

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

function getContent(id: String) {
    var player: Character = self.getOwner();
    var resource = player.getAssistContentStat("spriteContent") + "controller";
    return resource;
}

function currentMode() {
    var player: Character = self.getOwner();
    var costume = player.getPlayerConfig().assistCostume;
    return modes[costume];
}

function slug(mode: String) {
    return prefix + mode;
}

function displayMode() {
    var player: Character = self.getOwner();
    var container: Container = player.getDamageCounterContainer();
    var resource: String = player.getAssistContentStat("spriteContent") + mode;
    var sprite = Sprite.create(resource);
    sprite.scaleY = 0.6;
    sprite.scaleX = 0.6;
    sprite.y = sprite.y + 12;
    sprite.x = sprite.x + (8 * 13);
    container.addChild(sprite);
}
function isRunning() {
    var objs: Array<CustomGameObject> = match.getCustomGameObjects();
    var foundExisting = false;
    Engine.forEach(objs, function (obj: CustomGameObject, _idx: Int) {
        if (obj.exports.specialModeType == slug(mode)) {
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
        controller.exports.specialModeType = slug(mode);
    }
}

function initialize() {
    mode = currentMode();


}

function enableMode() {
    switch (mode) {
        case ("none"): return;
        case ("mega"): enableMegaMode();
        case ("mini"): enableMiniMode();
        case ("heavy"): enableHeavyMode();
        case ("light"): enableLightMode();
        case ("smash64"): enableSmash64();
        case ("vampire"): enableVampireMode();
        case ("vengeance"): enableVengeanceMode();
        case ("turbo"): enableTurboMode();
        case ("dramatic"): enableDramaticMode();
        case ("critical"): enableCriticalMode();
        case ("ssf1"): enableSSF1Mode();
        case ("exmode"): enableEXMode();
        default: return;
    }
    createController();
    displayMode();

}
function update() {
    var player: Character = self.getOwner();
    player.setAssistCharge(0);
    if (match.getPlayers().length > 1 && !enabled.get()) {
        var port = player.getPlayerConfig().port;
        Engine.log("Player " + port);
        enabled.set(true);
        player.addTimer((1 + port) * 5, 1, function () {
            enableMode();
        }, { persistent: true });
    }
}
function onTeardown() {
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

    createController();
}

function vampire(event: GameObjectEvent) {

    event.data.self.addDamage(Math.ceil(event.data.hitboxStats.damage / -2));

}

function enableVampireMode() {
    if (!isRunning()) {
        var players = match.getPlayers();
        Engine.forEach(players, function (player: Character, _idx: Int) {
            player.addEventListener(GameObjectEvent.HIT_DEALT, vampire, { persistent: true });
            return true;
        }, []);

    }
}


function turbo(event: GameObjectEvent) {
    var p: Character = event.data.self;
    p.updateAnimationStats({ interruptible: true });
}

function enableTurboMode() {
    if (!isRunning()) {
        var players = match.getPlayers();
        Engine.forEach(players, function (player: Character, _idx: Int) {
            player.addEventListener(GameObjectEvent.HIT_DEALT, turbo, { persistent: true });
            return true;
        }, []);
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


}


function willCrit() {
    return Random.getInt(1,16) == 8;
}

function enableCriticalMode() {
    var players = match.getPlayers();
    if (!isRunning()) {
        Engine.forEach(players, function (player: Character, _idx: Int) {
            player.addTimer(1, -1,
                function () {
                    if (willCrit()) {
                        player.addEventListener(GameObjectEvent.HIT_DEALT, visuals);
                        player.addEventListener(GameObjectEvent.HITBOX_CONNECTED, boostStats);

                    }
                }
                , { persistent: true });
            return true;
        }, []);
    }

}

function enableHeavyMode() {
    if (!isRunning()) {
        Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
            player.addStatusEffect(StatusEffectType.GRAVITY_MULTIPLIER, 2);
            return true;
        }, []);
    }
}

function enableLightMode() {
    if (!isRunning()) {
        Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
            player.addStatusEffect(StatusEffectType.GRAVITY_MULTIPLIER, 0.5);
            return true;
        }, []);
    }
}

function makeMega(obj: GameObject) {
    obj.setScaleX(2);
    obj.setScaleY(2);
}

function enableMegaMode() {
    if (!isRunning()) {
        Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
            player.addStatusEffect(StatusEffectType.SIZE_MULTIPLIER, 2);
            player.addStatusEffect(StatusEffectType.JUMP_SPEED_MULTIPLIER, 1.4);
            player.addStatusEffect(StatusEffectType.DOUBLE_JUMP_SPEED_MULTIPLIER, 1.4);
            player.addStatusEffect(StatusEffectType.HITBOX_DAMAGE_MULTIPLIER, 1.3);

            player.addEventListener(GameObjectEvent.PROJECTILE_CREATED, function (event: GameObjectEvent) {
                Engine.forEach(match.getProjectiles(), function (projectile: Projectile, _idx: Int) {
                    makeMega(projectile);
                    return true;
                }, []);

            }, { persistent: true });
            return true;
        }, []);
    }
}

function makeMini(obj: GameObject) {
    obj.setScaleX(0.5);
    obj.setScaleY(0.5);

}

function enableMiniMode() {
    if (!isRunning()) {
        Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
            player.addStatusEffect(StatusEffectType.SIZE_MULTIPLIER, 0.5);
            player.addStatusEffect(StatusEffectType.JUMP_SPEED_MULTIPLIER, 0.7);
            player.addStatusEffect(StatusEffectType.DOUBLE_JUMP_SPEED_MULTIPLIER, 0.7);
            player.addStatusEffect(StatusEffectType.HITBOX_DAMAGE_MULTIPLIER, 0.5);
            player.addEventListener(GameObjectEvent.PROJECTILE_CREATED, function (event: GameObjectEvent) {
                Engine.forEach(match.getProjectiles(), function (projectile: Projectile, _idx: Int) {
                    makeMini(projectile);
                    return true;
                }, []);

            }, { persistent: true });
            return true;
        }, []);
    }

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
        player.updateCharacterStats({ grabAirType: GrabAirType.GRAB });
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
    if (!isRunning()) {
        Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
            exMode(player);
            return true;
        }, []);
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

}

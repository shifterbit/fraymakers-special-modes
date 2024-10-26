// Runs on object init

// DO NOT TOUCH
var enabled = self.makeBool(false);
var prefix = "specialModeType_";
var globalMode = "none";
var timeLeft = self.makeInt(60 * 60 * 5);
var MISSION_FAIL = -1;
var MISSION_SUCCESS = 1;
var MISSION_PENDING = 0;
var globalController: CustomGameObject = null;
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
    "exmode",
    "coin",
    //  "ultimate"
];

var indicatedModes = [
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
    "exmode",
];

var conflicts: Array<Array<String>> = [
    [],
    ["mini"],
    ["mega"],
    ["light"],
    ["heavy"],
    [],
    ["vengeance"],
    ["vampire"],
    [],
    [],
    [],
    [],
    [],
    [],
    //  []
];

function parseDigit(digit: String) {
    switch (digit) {
        case "9": return 9;
        case "8": return 8;
        case "7": return 7;
        case "6": return 6;
        case "5": return 5;
        case "4": return 4;
        case "3": return 3;
        case "2": return 2;
        case "1": return 1;
        case "0": return 0;
        default: return 0;
    }
}



function parseStringArray(arr: Array<String>) {
    total = 0;
    var pow = arr.length - 1;
    var curr = 0;
    while (curr <= arr.length - 1) {
        var digit = parseDigit(arr[curr]);
        total += digit * Math.pow(10, pow);
        curr++;
        pow--;
    }
    return total;
}




function intToLeftPaddedStringArray(num: Int, length: Int) {
    var s = "" + Math.round(num);
    s = s.split("");
    var arr = [];
    var i = 0;
    var j = length - s.length;
    while (i < j) {
        arr.push("0");
        i++;
    }

    for (i in s) {
        arr.push(i);
    }
    return arr;
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

function getContent(id: String) {
    var player: Character = self.getOwner();
    var resource = player.getAssistContentStat("spriteContent") + id;
    return resource;
}

function currentMode() {
    var player: Character = self.getOwner();
    var costume = player.getPlayerConfig().assistCostume;
    return modes[costume];
}

function modeIdx(mode: String) {
    var i = 0;
    Engine.forEach(modes, function (md: String, idx: Int) {
        if (md == mode) {
            i = idx;
            return false;
        }
        return true;
    }, []);
    return i;
}

function slug(mode: String) {
    return prefix + mode;
}

function displayMode() {
    if (indicatedModes.indexOf(globalMode) > 0) {
        var player: Character = self.getOwner();
        var container: Container = player.getDamageCounterContainer();
        var resource: String = player.getAssistContentStat("spriteContent") + globalMode;
        var sprite = Sprite.create(resource);
        sprite.scaleY = 0.6;
        sprite.scaleX = 0.4;
        sprite.y = sprite.y + 12;
        sprite.x = sprite.x + (8 * 15);
        container.addChild(sprite);
        if (isRunning(globalMode)) {
            var filter = new HsbcColorFilter();
            //filter.hue = Math.toRadians(180);
            // filter.contrast = 0;
            filter.brightness = -70 / 100;
            sprite.addFilter(filter);
        }
    }
}
function isRunning(mode: String) {
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
    return foundExisting;
}

function createController(mode: String) {
    if (!isRunning(mode)) {
        var player: Character = self.getOwner();
        var resource: String = player.getAssistContentStat("spriteContent") + "controller";
        var controller: CustomGameObject = match.createCustomGameObject(resource, player);
        controller.exports.specialModeType = slug(mode);
        controller.exports.data = {};
        if (mode == globalMode) {
            globalController = controller;
        }
        for (conflict in conflicts[modeIdx(mode)]) {
            createController(conflict);
        }
    }
}

function initialize() {
    globalMode = currentMode();


}

function enableMode() {
    if (!isRunning(globalMode)) {
        displayMode();
        createController(globalMode);
        switch (globalMode) {
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
            case ("coin"): { enableCoins(); };
            default: { enableUltimateMode(); };
        }
    }

}
function update() {
    var player: Character = self.getOwner();
    player.setAssistCharge(0);
    if (match.getPlayers().length > 1 && !enabled.get()) {
        var port = player.getPlayerConfig().port;
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
    var players = match.getPlayers();
    Engine.forEach(players, function (player: Character, _idx: Int) {
        player.addEventListener(GameObjectEvent.HIT_DEALT, vengeance, { persistent: true });
        return true;
    }, []);

}

function vampire(event: GameObjectEvent) {

    event.data.self.addDamage(Math.ceil(event.data.hitboxStats.damage / -2));

}

function enableVampireMode() {
    var players = match.getPlayers();
    Engine.forEach(players, function (player: Character, _idx: Int) {
        player.addEventListener(GameObjectEvent.HIT_DEALT, vampire, { persistent: true });
        return true;
    }, []);
}


function turbo(event: GameObjectEvent) {
    var p: Character = event.data.self;
    p.updateAnimationStats({ interruptible: true });
}

function enableTurboMode() {
    var players = match.getPlayers();
    Engine.forEach(players, function (player: Character, _idx: Int) {
        player.addEventListener(GameObjectEvent.HIT_DEALT, turbo, { persistent: true });
        return true;
    }, []);
}


function zoomInOnFoe(event: GameObjectEvent) {
    var foe: Character = event.data.foe;

    camera.addForcedTarget(foe);
    camera.setMode(1);


    event.data.self.addTimer(2, 10, function () {
        match.freezeScreen(1, []);
    }, { persistent: true });


    event.data.self.addTimer(20, 1, function () {
        camera.setMode(0);
        camera.deleteForcedTarget(foe);
        camera.addTarget(foe);
    }, { persistent: true });
}


function toCriticalHIt(event: GameObjectEvent) {
    event.data.hitboxStats.damage = event.data.hitboxStats.damage * 1.7;
    event.data.hitboxStats.knockbackGrowth = event.data.hitboxStats.knockbackGrowth + 10;
}

function increaseHitStop(event: GameObjectEvent) {
    event.data.hitboxStats.hitstopMultiplier = 5;
    event.data.hitboxStats.hitstopOffset = 10;
    event.data.hitboxStats.selfHitstopOffset = 10;



}

function enableDramaticMode() {
    var players = match.getPlayers();
    Engine.forEach(players, function (player: Character, _idx: Int) {
        player.addEventListener(GameObjectEvent.HIT_DEALT, zoomInOnFoe, { persistent: true });
        player.addEventListener(GameObjectEvent.HITBOX_CONNECTED, increaseHitStop, { persistent: true });

        return true;
    }, []);
}


function willCrit() {
    return Random.getInt(1, 16) == 8;
}

function enableCriticalMode() {
    var players = match.getPlayers();
    Engine.forEach(players, function (player: Character, _idx: Int) {
        player.addEventListener(GameObjectEvent.HITBOX_CONNECTED, function (event: GameObjectEvent) {
            if (willCrit()) {
                toCriticalHIt(event);
                player.addEventListener(GameObjectEvent.HIT_DEALT, zoomInOnFoe);
            }
        }, { persistent: true });

        return true;
    }, []);

}

function enableHeavyMode() {
    Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
        player.addStatusEffect(StatusEffectType.GRAVITY_MULTIPLIER, 2);
        return true;
    }, []);
}

function enableLightMode() {
    Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
        player.addStatusEffect(StatusEffectType.GRAVITY_MULTIPLIER, 0.5);
        return true;
    }, []);
}

function makeMega(obj: GameObject) {
    obj.setScaleX(2);
    obj.setScaleY(2);
}

function enableMegaMode() {
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

function makeMini(obj: GameObject) {
    obj.setScaleX(0.5);
    obj.setScaleY(0.5);

}

function enableMiniMode() {
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
    Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
        exMode(player);
        return true;
    }, []);
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
    Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
        ssf1Mode(player);
        return true;
    }, []);
    Engine.forEach(match.getStructures(), function (structure: Structure, _idx: Int) {
        structure.updateStructureStats({ leftLedge: false, rightLedge: false, dropThrough: false });
        return true;
    }, []);

}

function disableAllAttacks(obj: Character) {
    //obj.getStatusEffectByType(StatusEffectType.)
    var tag = "ultimateAirDodge";
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.AERIAL_NEUTRAL, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.AERIAL_FORWARD, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.AERIAL_DOWN, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.AERIAL_BACK, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.AERIAL_UP, { tag: tag });

    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.SPECIAL_UP, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.SPECIAL_DOWN, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.SPECIAL_SIDE, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.SPECIAL_NEUTRAL, { tag: tag });

    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_DOWN, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_FORWARD, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_UP, { tag: tag });

    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.JAB, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.TILT_FORWARD, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.TILT_DOWN, { tag: tag });
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.TILT_UP, { tag: tag });


}
function enableAirActions(obj: Character, tag: String) {
    return function (event: GameObjectEvent) {
        var disabledStatus = obj.findStatusEffectObjectsByTag(StatusEffectType.DISABLE_ACTION, tag);
        Engine.forEach(disabledStatus, function (effect: any, _idx: Int) {
            obj.removeStatusEffect(StatusEffectType.DISABLE_ACTION, effect.id);
        }, []);
    }
}

function ultimateMode(obj: Character) {
    var tag = "ultimateAirDodge";
    obj.updateCharacterStats({ airdashInitialSpeed: 3, airdashSpeedCap: 6, airdashStartupLength: 1, airdashFullspeedLength: 30 });
    obj.addEventListener(GameObjectEvent.LAND, enableAirActions(obj, tag), { persistent: true });
    obj.updateCharacterStats({ airdashTrailEffect: getContent("controller") });
    var neutralAirDash = function () {
        obj.setXSpeed(0);
        obj.setYSpeed(0);
    };
    var dodgeRollSpeed = obj.getCharacterStat("dodgeRollSpeed");
    var jumps = obj.getDoubleJumpCount();
    obj.addTimer(1, -1, function () {
        var disabledStatus = obj.findStatusEffectObjectsByTag(StatusEffectType.DISABLE_ACTION, tag);
        var heldControls = obj.getHeldControls();
        var up = heldControls.UP;
        var down = heldControls.DOWN;
        var right = heldControls.RIGHT;
        var left = heldControls.LEFT;
        var shields = heldControls.SHIELD || heldControls.SHIELD1 || heldControls.SHIELD2;
        var neutral = !(up || left || down || right);

        if (neutral
            && shields
            && obj.inStateGroup(CStateGroup.JUMP)
            && obj.getHitstun() == 0
            && obj.getHitstop() == 0) {
            obj.setXSpeed(0.1);
            obj.setYSpeed(-0.1);
            obj.updateCharacterStats({ airdashSpeedCap: 0.001, airdashStartupLength: 0, airdashFullspeedLength: 40 });
            obj.playAnimation("spot_dodge");



        } else if (!obj.inStateGroup(CStateGroup.AIRDASH)) {
            obj.updateCharacterStats({ airdashSpeedCap: 6, airdashStartupLength: 3, airdashFullspeedLength: 30 });
        }
        if (obj.inStateGroup(CStateGroup.AIRDASH)) {
            if (disabledStatus == null) {
                disableAllAttacks(obj);
                Engine.log("Disabled Attacks");
                Engine.log("Disabled Jumps");
                if (neutral) {
                    obj.resetMomentum();
                    obj.updateCharacterStats({ dodgeRollSpeed: 0 });
                    obj.toState(CState.AIRDASH_INITIAL, "roll");
                }
            }
        }
        if (obj.isOnFloor()) {
            obj.updateCharacterStats({ dodgeRollSpeed: dodgeRollSpeed });

        }

        if (obj.inState(CState.AIRDASH_DECELERATING)) {
            Engine.log("Entered End");
            obj.setXSpeed(0);
            obj.setYSpeed(0);
            obj.resetMomentum();
            obj.setDoubleJumpCount(0);
            Engine.log(obj.getDoubleJumpCount());

        }
        if (obj.getPreviousState() == CState.AIRDASH_FULL_SPEED || obj.getPreviousStateGroup(CStateGroup.AIRDASH)) {
            Engine.log("LEFT AIR DASH");
            obj.endAnimation();
            obj.toState(CState.FALL);
            var gravity = obj.getGameObjectStat("gravity");
            var dodgeTime = 25 / gravity;
            obj.addTimer(dodgeTime, 1, function () {
                enableAirActions(obj, tag)(null);
                Engine.log(obj.getDoubleJumpCount());
                obj.setDoubleJumpCount(jumps);
                Engine.log([gravity, dodgeTime]);
            }, { persistent: true });

        }

        if (obj.inStateGroup(CStateGroup.AIRDASH)) {
            obj.updateAnimationStats({ bodyStatus: BodyStatus.INTANGIBLE });

        }


    }, { persistent: true });

}
function enableUltimateMode() {
    Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
        ultimateMode(player);
        return true;
    }, []);


}
function smash64Mode(obj: Character) {
    obj.addStatusEffect(StatusEffectType.ATTACK_HITSTUN_MULTIPLIER, 1.5);
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.SPECIAL_SIDE);
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.THROW_DOWN);
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.THROW_UP);
    obj.updateCharacterStats({ airdashLimit: 0 });


    obj.addTimer(1, -1, function () {
        if (obj.inStateGroup(CStateGroup.ATTACK)) {
            switch (obj.getState()) {
                case CState.STRONG_DOWN_CHARGE: {
                    obj.toState(CState.STRONG_DOWN_ATTACK);
                };
                case CState.STRONG_UP_CHARGE: {
                    obj.toState(CState.STRONG_UP_ATTACK);
                };
                case CState.STRONG_FORWARD_CHARGE: {
                    obj.toState(CState.STRONG_FORWARD_ATTACK);
                };
                default: { };
            }
        }
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
    Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
        smash64Mode(player);
        return true;
    }, []);


}



function releaseCoinsEvent(event: GameObjectEvent) {
    var damage = event.data.hitboxStats.damage;
    var target = event.data.self;
    if (event.data.foe.exports.coin == null
        && damage >= 0 && !target.hasBodyStatus(BodyStatus.INTANGIBLE)
        && !target.hasBodyStatus(BodyStatus.INVINCIBLE)) {
        releaseCoins(target, Math.round(damage));
    }
}
function coinMode(player: Character) {
    var coinSprites = setupCoins(player);
    var port = player.getPlayerConfig().port;
    globalController.exports.data.coinSprites[port] = coinSprites;
    player.addEventListener(CharacterEvent.RESPAWN, function (event: CharacterEvent) {
        var target: Character = event.data.self;
        var targetPort = target.getPlayerConfig().port;
        var coins = globalController.exports.data.coins[targetPort];
        var newCoins = Math.round(coins / 2);
        globalController.exports.data.coins[targetPort] = newCoins;
        var coinSprites = globalController.exports.data.coinSprites[targetPort];
        refreshCoins(coinSprites, newCoins);
    }, { persistent: true });
    player.addEventListener(GameObjectEvent.HIT_RECEIVED, releaseCoinsEvent, { persistent: true });

}

function releaseCoins(player: Character, damage: Int) {
    var coinResource = getContent("coinProj");
    var remaining: Int = damage;
    var numGold = Math.floor(remaining / 10);
    remaining -= (numGold * 10);
    var numSilver = Math.floor(remaining / 5);
    remaining -= (numSilver * 5);
    var numBronze = remaining;
    var recalculatedTotal = (numBronze * 1) + (numSilver * 5) + (numGold * 10);
    var coinDamageListener = function (damage: Int) {
        return function (event: GameObjectEvent) {
            if (event.data.foe.getType() == EntityType.CHARACTER) {
                var foe: Character = event.data.foe;
                var foePort = foe.getPlayerConfig().port;
                globalController.exports.data.coins[foePort] += Math.round(damage);
                if (globalController.exports.data.coins[foePort] >= 9999) {
                    globalController.exports.data.coins[foePort] = 9999;
                }
                var coins = globalController.exports.data.coins[foePort];
                var coinSprites = globalController.exports.data.coinSprites[foePort];
                refreshCoins(coinSprites, coins);
                event.data.self.destroy();
            }
        };
    }
    var goldListener = coinDamageListener(10);
    var silverListener = coinDamageListener(5);
    var bronzeListener = coinDamageListener(1);
    Engine.forCount(numGold, function (idx: Int) {
        var proj = match.createProjectile(coinResource, player);
        proj.addEventListener(GameObjectEvent.HIT_DEALT, goldListener, { persistent: true });
        proj.playAnimation("gold");
        proj.setScaleX(4);
        proj.setScaleY(4);
    }, []);

    Engine.forCount(numSilver, function (idx: Int) {
        var proj = match.createProjectile(coinResource, player);
        proj.addEventListener(GameObjectEvent.HIT_DEALT, silverListener, { persistent: true });
        proj.playAnimation("silver");
        proj.setScaleX(3);
        proj.setScaleY(3);
    }, []);
    Engine.forCount(numBronze, function (idx: Int) {
        var proj = match.createProjectile(coinResource, player);
        proj.addEventListener(GameObjectEvent.HIT_DEALT, bronzeListener, { persistent: true });
        proj.playAnimation("bronze");
        proj.setScaleX(2);
        proj.setScaleY(2);
    }, []);

}


function setupCoins(player: Character) {
    var resource = getContent("number");
    var curr = 0;
    var sprites: Array<Sprite> = [];
    var container: Container = player.getDamageCounterContainer();
    var icon = Sprite.create(getContent("coinProj"));
    icon.currentAnimation = "gold";
    icon.x = icon.x + 16;
    icon.y = icon.y - 16;
    container.addChild(icon);

    while (curr < 4) {
        var sprite: Sprite = Sprite.create(resource);
        sprite.currentFrame = 1;
        sprite.x = sprite.x + 32 + (16 * curr);
        sprite.y = sprite.y - 16;
        container.addChild(sprite);
        sprites.push(sprite);
        curr++;
    }
    return sprites;
}


function refreshCoins(sprites: Array<Sprite>, coins: Int) {
    var nums = intToLeftPaddedStringArray(coins, 4);
    var curr = 0;
    while (curr < 4) {
        sprites[curr].currentFrame = parseDigit(nums[curr]) + 1;
        curr++;
    }

}


function coinModeWinners() {
    var players: Array<Character> = match.getPlayers();
    var highest = 0;
    var winningPlayer = null;


    Engine.forEach(players, function (player: Character, _idx: Int) {
        var port = player.getPlayerConfig().port;
        var coins = globalController.exports.data.coins[port];
        if (coins >= highest) {
            winningPlayer = player;
            highest = coins;
        }
        return true;
    }, []);
    if (highest == 0) {
        return match.getPlayers();
    }

    var winners = [winningPlayer];

    Engine.forEach(players, function (player: Character, _idx: Int) {
        var port = player.getPlayerConfig().port;
        var coins = globalController.exports.data.coins[port];
        if (coins == highest && player != winningPlayer) {
            winners.push(player);
            highest = coins;
        }
        return true;
    }, []);

    return winners;
}

//function teleportToOppositeBlastZone

function pacmanMode(duration: Int) {
    var deathBounds = stage.getDeathBounds();
    var minY = deathBounds.getY();
    var maxY = -minY;
    var minX = deathBounds.getX();
    var maxX = -minX;
    Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
        player.addTimer(1, duration, function () {
            var x = player.getX();
            var y = player.getY();

            var hitLeftBlastZone = x <= minX * 0.9;
            var hitRightBlastZone = x >= maxX * 0.9;
            var hitUpBlastZone = y <= minY * 0.9;
            var hitDownBlastZone = y >= maxY * 0.9;
            if (hitRightBlastZone) {
                player.setX(minX + Math.abs(minX * 0.2));
            }
            if (hitLeftBlastZone) {
                player.setX(maxX - Math.abs(maxX * 0.2));
            }
            if (hitUpBlastZone) {
                player.setY(maxY - Math.abs(maxY * 0.2));
            }
            if (hitDownBlastZone) {
                player.setY(minY + Math.abs(minY * 0.2));
            }

        }, { persistent: true });


    }, []);




}


function enableCoins() {
    if (match.getMatchSettingsConfig().time > 0) {
        timeLeft.set(match.getMatchSettingsConfig().time * 60);
    }
    var deathBounds = stage.getDeathBounds();

    var p: Character = self.getOwner();
    var players = match.getPlayers();
    p.addTimer(70, 1, function () {

        var timeSprites = [];
        p.addTimer(1, -1, function () {
            if (match.getMatchSettingsConfig().time == 0) {
                var frames = timeLeft.dec();
                var timeString = Engine.framesToTimeString(frames);
                var timeObj = parseTimeString(timeString);
                var ts = renderTime(timeObj, timeSprites, globalController.getViewRootContainer());
                var container = camera.getForegroundContainer();
                container.rotation = 0;
                container.addChildAt(globalController.getViewRootContainer(), 0);
                timeSprites = ts;
            } else {
                timeLeft.dec();
            }


            if (timeLeft.get() == 30) {

                var winners = coinModeWinners();
                Engine.forEach(players, function (player: Character, _idx: Int) {
                    player.removeEventListener(GameObjectEvent.HIT_RECEIVED, releaseCoinsEvent);
                    return true;
                }, []);

                if (winners.length == 1) {
                    var player = winners[0];
                    camera.addForcedTarget(player);
                    camera.setMode(1);
                    if (!player.isOnFloor()) {
                        var port = player.getPlayerConfig().port;
                        var startingPos = globalController.exports.data.spawnPositions[port];
                        player.setX(startingPos.x);
                        player.setY(startingPos.y);
                        player.resetMomentum();
                    }

                    Engine.forEach(player.getFoes(), function (foe: Character, _idx: Int) {
                        foe.addEventListener(GameObjectEvent.HITBOX_CONNECTED, function (event: GameObjectEvent) {
                            event.data.hitboxStats.damage = 0;
                            event.data.hitboxStats.baseKnockback = 0;
                        }, { persistent: true });

                        foe.setLives(1);
                        foe.addTimer(20, 5, function () {
                            foe.setX(99999);
                            foe.setY(99999);
                        }, { persistent: true });
                        return true;
                    }, []);
                } else {
                    Engine.forEach(players, function (player: Character, _idx: Int) {
                        player.setLives(1);
                        player.addTimer(1, 20, function () {
                            if (winners.indexOf(player) < 0) {
                                player.setX(99999);
                                player.setY(99999);
                            }
                        }, { persistent: true });
                        return true;
                    }, []);
                    Engine.forEach(winners, function (player: Character, _idx: Int) {
                        var port = player.getPlayerConfig().port;
                        var startingPos = globalController.exports.data.spawnPositions[port];
                        player.endAnimation();
                        player.setX(startingPos.x);
                        player.setY(startingPos.y);
                        player.resetMomentum();
                        player.setDamage(300);
                        player.setLives(2);
                        player.setX(99999999);
                        player.addTimer(1, -1, function () {
                            if (player.getDamage() < 300) {
                                player.takeHit({ damage: 300, true: false, baseKnockback: 0 });
                                player.setDamage(300);
                                player.validateHit({});
                            }

                        }, { persistent: true });
                        return true;
                    }, []);

                    Engine.forEach(match.getProjectiles(), function (projectile: Projectile, _idx: Int) {
                        projectile.kill();
                        return true;
                    }, []);

                }
            }

        }, { persistent: true, condition: function () { return timeLeft.get() >= 1; } });
    }, { persistent: true });




    globalController.exports.data = { coins: [0, 0, 0, 0], coinSprites: [[], [], [], []], spawnPositions: [{}, {}, {}, {}] };
    Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
        var port = player.getPlayerConfig().port;
        globalController.exports.data.spawnPositions[port] = { x: player.getX(), y: player.getY() };
        player.setLives(-1);
        coinMode(player);
        return true;
    }, []);

}

function parseTimeString(text: String) {
    var times = [[], [], []];
    var curr = 0;
    var out = 0;
    while (curr < text.length) {
        var char = text.charAt(curr);
        if (char == ":") {
            out = 1;
        } else if (char == "'") {
            out = 2;
        } else {
            times[out].push(char);
        }
        curr++;
    }
    return {
        minutes: times[0],
        seconds: times[1],
        milliseconds: times[2]
    };

}

function renderTime(time: Int, sprites: Array<Sprite>, container: Container) {
    var resource = getContent("number");
    var baseOffset = 16;
    var minutes = time.minutes;
    var seconds = time.seconds;
    var milliseconds = time.milliseconds;
    var maxLength = milliseconds.length + seconds.length + minutes.length + 2;

    var totalLength = minutes.length + seconds.length + milliseconds.length;
    var untrimmed = sprites.length - totalLength.length;
    if (untrimmed > 0) {
        Engine.forCount(untrimmed, function (idx: Int) {
            sprites[idx].dispose();
            return true;
        }, []);
    }
    var makeSprite = function (frame: Int, pos: Int, animation: String) {
        var sprite: Sprite = Sprite.create(resource);
        var filter = new HsbcColorFilter();
        filter.hue = 25;
        //filter.hue = -90;

        sprite.addFilter(filter);
        sprite.currentAnimation = animation;
        sprite.x = 500 + (baseOffset) * (1 + pos);
        sprite.y = 32;
        sprite.scaleX = 1;
        sprite.scaleY = 1;
        sprite.currentFrame = frame;
        return sprite;
    }

    var insertSprite = function (sprite: Sprite, pos: Int) {
        if (sprites[pos] == null) {
            sprites[pos] = sprite;
            container.addChild(sprite);
        } else {
            sprites[pos].currentFrame = frame;
        }
    }

    sprites = sprites.slice(untrimmed, sprites.length);
    var curr = 0;
    var minutePos = 0;
    while (minutePos < minutes.length) {
        var frame = parseDigit(minutes[minutePos]) + 1;
        var sprite = makeSprite(frame, curr, "digit");
        insertSprite(sprite, curr);
        minutePos++;
        curr++;
    }

    var colon = makeSprite(1, curr, "symbol");
    insertSprite(colon, curr);
    curr++;

    var secondPos = 0;
    while (secondPos < seconds.length) {
        var frame = parseDigit(seconds[secondPos]) + 1;
        var sprite = makeSprite(frame, curr, "digit");
        insertSprite(sprite, curr);

        secondPos++;
        curr++;
    }


    var colon = makeSprite(1, curr, "symbol");
    insertSprite(colon, curr);
    curr++;


    var milliPos = 0;
    while (milliPos < milliseconds.length && curr < maxLength) {
        var frame = parseDigit(milliseconds[milliPos]) + 1;
        var sprite = makeSprite(frame, curr, "digit");
        insertSprite(sprite, curr);
        milliPos++;
        curr++;
    }


    return sprites;

}

function failMissionEvent(event: GameObjectEvent) {
    var player: Character = event.data.self;
    var port = player.getPlayerConfig().port;

    globalController.exports.data.missionStatus[port] = MISSION_FAIL;
}
function succeedMissionEvent(event: GameObjectEvent) {
    var player: Character = event.data.self;
    var port = player.getPlayerConfig().port;

    globalController.exports.data.missionStatus[port] = MISSION_SUCCESS;
}

function failedMission(player: Character) {
    var port = player.getPlayerConfig().port;
    var failed = globalController.exports.data.missionStatus[port] == MISSION_FAIL;

    return failed;
}

function failedMission(player: Character) {
    var port = player.getPlayerConfig().port;
    var succeeded = globalController.exports.data.missionStatus[port] == MISSION_SUCCESS;

    return succeeded;
}


function regenBuff(player: Character, duration: Int) {
    var outerGlow = new GlowFilter();
    outerGlow.color = 0xff8c69;
    var innerGlow = new GlowFilter();
    innerGlow.color = 0xFFFFFF;
    player.addFilter(innerGlow);
    player.addFilter(outerGlow);
    player.addTimer(10, Math.floor(duration / 10), function () {
        player.addDamage(-0.5);
    }, { persistent: true });

    player.addTimer(duration, 1, function () {
        player.removeFilter(innerGlow);
        player.removeFilter(outerGlow);
    }, { persistent: true });
}

function mobilityBuff(player: Character, duration: Int) {
    var outerGlow = new GlowFilter();
    outerGlow.color = 0x00cc99;
    var innerGlow = new GlowFilter();
    innerGlow.color = 0xFFFFFF;
    player.addFilter(innerGlow);
    player.addFilter(outerGlow);
    var tag = "speedBuff";
    var airSpeed = player.addStatusEffect(StatusEffectType.AERIAL_SPEED_ACCELERATION_MULTIPLIER, 1.1, { tag: tag });
    var groundSpeed = player.addStatusEffect(StatusEffectType.GROUND_SPEED_ACCELERATION_MULTIPLIER, 1.1, { tag: tag });

    player.addTimer(duration, 1, function () {
        player.removeStatusEffect(StatusEffectType.AERIAL_SPEED_ACCELERATION_MULTIPLIER, airSpeed);
        player.removeStatusEffect(GROUND_SPEED_ACCELERATION_MULTIPLIER, groundSpeed);
        player.removeFilter(innerGlow);
        player.removeFilter(outerGlow);
    }, { persistent: true });
}


function protectionbuff(player: Character, duration: Int) {
    var outerGlow = new GlowFilter();
    outerGlow.color = 0x00bfff;
    var innerGlow = new GlowFilter();
    innerGlow.color = 0xFFFFFF;
    player.addFilter(innerGlow);
    player.addFilter(outerGlow);
    var hitReceived = function (event: GameObjectEvent) {
        player.setKnockback(player.getKnockback() * 0.9);
        var damageDiff = Math.ceil(-0.75 * event.data.hitboxStats.damage);
        player.addDamage(damageDiff);
    };

    player.addEventListener(GameObjectEvent.HIT_RECEIVED, hitReceived, { persistent: true });
    player.addTimer(duration, 1, function () {
        player.removeEventListener(GameObjectEvent.HIT_RECEIVED, hitReceived);
        player.removeFilter(innerGlow);
        player.removeFilter(outerGlow);
    }, { persistent: true });

}


function damageBuff(player: Character, duration: Int) {
    var outerGlow = new GlowFilter();
    outerGlow.color = 0xFF0000;
    var innerGlow = new GlowFilter();
    innerGlow.color = 0xFFFFFF;
    player.addFilter(innerGlow);
    player.addFilter(outerGlow);
    var tag = "damageBuff";
    var damage = player.addStatusEffect(StatusEffectType.HITBOX_DAMAGE_MULTIPLIER, 1.1, { tag: tag });
    var hitstun = player.addStatusEffect(StatusEffectType.ATTACK_HITSTUN_MULTIPLIER, 1.1, { tag: tag });
    var knockback = player.addStatusEffect(StatusEffectType.ATTACK_KNOCKBACK_MULTIPLIER, 1.1, { tag: tag });

    player.addTimer(duration, 1, function () {
        player.removeStatusEffect(StatusEffectType.HITBOX_DAMAGE_MULTIPLIER, damage);
        player.removeStatusEffect(StatusEffectType.ATTACK_HITSTUN_MULTIPLIER, hitstun);
        player.removeStatusEffect(StatusEffectType.ATTACK_KNOCKBACK_MULTIPLIER, knockback);
        player.removeFilter(innerGlow);
        player.removeFilter(outerGlow);
    }, { persistent: true });
}





function noHit(duration: Int) {
    var players: Array<Character> = match.getPlayers();
    Engine.forEach(players, function (player: Character, _idx: Int) {
        var port = player.getPlayerConfig().port;
        player.addEventListener(GameObjectEvent.ENTER_HITSTUN, failMissionEvent, { persistent: true });
        player.addTimer(duration, 1, function () {
            if (!failedMission(player)) {
                globalController.exports.data.missionStatus[port] = MISSION_SUCCESS;
            }
        }, { persistent: true });
    }, []);
}



function dealDamage(duration: Int, damage: Int) {
    var players: Array<Character> = match.getPlayers();
    var addDamage = function (event: GameObjectEvent) {
        var player: Character = event.data.self;
        var port: Int = player.getPlayerConfig().port;
        globalController.exports.data.missionData[port].damage += event.data.hitboxStats.damage;
        if (globalController.exports.data.missionData[port].damage >= damage) {
            globalController.exports.data.missionStatus[port] = MISSION_SUCCESS;
        } else {
            globalController.exports.data.missionStatus[port] = MISSION_FAIL;
        }

    }
    Engine.forEach(players, function (player: Character, _idx: Int) {
        var port = player.getPlayerConfig().port;
        globalController.exports.data.missionData[port] = { damage: 0 };

        player.addEventListener(GameObjectEvent.HIT_DEALT, addDamage, { persistent: true });
        player.addTimer(duration, 1, function () {
            player.removeEventListener(GameObjectEvent.HIT_DEALT, addDamage);
        }, { persistent: true });
    }, []);

}
function resetMissionMode() {
    globalController.exports.data = { missionStatus: [MISSION_PENDING, MISSION_PENDING, MISSION_PENDING, MISSION_PENDING], missionData: [{}, {}, {}, {}] };

}

function enableMissionMode() {
    globalController.exports.data = { missionStatus: [MISSION_PENDING, MISSION_PENDING, MISSION_PENDING, MISSION_PENDING], missionData: [{}, {}, {}, {}] };


}


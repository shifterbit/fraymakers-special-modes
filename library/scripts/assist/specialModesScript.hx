// Runs on object init

// DO NOT TOUCH
var actionable_animations: Array<String> = [
    "parry_success",
    "stand", "stand_turn", "idle",
    "walk", "walk_in", "walk_out", "walk_loop",
    "run", "run_turn", "skid",
    "jump_squat", "jump_in", "jump_out", "jump_midair", "jump_loop",
    "fall_loop", "fall_in", "fall_out",
    "crouch_loop", "crouch_in", "crouch_out",
    "dash", "airdash_land"
];
var enabled = self.makeBool(false);
var prefix = "specialModeType_";
var globalMode = "none";
var timeLeft = self.makeInt(60 * 60 * 5);
var globalDummy: Projectile = null;
var globalController: CustomGameObject = null;
var MISSION_FAIL = -1;
var MISSION_SUCCESS = 1;
var MISSION_PENDING = 0;
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
    "mission"
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
    []
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

function containsSubstring(text: String, substr: String) {
    if (substr.length > text.length) {
        return false;
    }
    var match = false;
    Engine.forCount(text.length - substr.length + 1, function (idx: Int) {
        var temp = text.substr(idx, idx + substr.length);
        if (temp == substr) {
            match = true;
            return false;
        }
        return true;
    }, []);
    return match;

}

/** 
 * Checks if any item in the array is either equal to or is a subtring of the target
 * @param {String[]} arr - array of strings
 * @param {String} target - target string
 */
function hasMatchOrSubstring(arr: Array<String>, target: String) {
    for (i in arr) {
        if (i == target || containsSubstring(target, i)) {
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
            case ("mission"): { enableMissionMode(); };
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
    if (!event.data.foe.hasBodyStatus(BodyStatus.INVINCIBLE)) {
        var foe: Character = event.data.foe;
        var duration = 20;

        camera.addForcedTarget(foe);
        camera.setMode(1);


        Engine.forEach(match.getPlayers(), function (p: Character) {
            p.getDamageCounterContainer().alpha = 0;
            return true;
        }, []);


        event.data.self.addTimer(2, duration / 2, function () {
            match.freezeScreen(1, []);
        }, { persistent: true });

        event.data.self.addTimer(10, 1, function () {
            foe.addEventListener(EntityEvent.COLLIDE_STRUCTURE, function (event: CharacterEvent) {
                camera.shake(10, 20);
            }, {});
        }, { persistent: true });

        event.data.self.addTimer(duration, 1, function () {
            camera.setMode(0);
            camera.deleteForcedTarget(foe);
            camera.addTarget(foe);
            Engine.forEach(match.getPlayers(), function (p: Character) {
                p.getDamageCounterContainer().alpha = 1;
                return true;
            }, []);
        }, { persistent: true });
    }
}

function zoomInOnSelf(event: GameObjectEvent) {
    if (!event.data.self.hasBodyStatus(BodyStatus.INVINCIBLE)) {
        var victim: Character = event.data.self;
        var duration = 30;

        camera.addForcedTarget(victim);
        camera.setMode(1);


        Engine.forEach(match.getPlayers(), function (p: Character) {
            p.getDamageCounterContainer().alpha = 0;
            return true;
        }, []);


        var dummy: Projectile = match.createProjectile(getContent("dummyProj"), null);

        dummy.addTimer(4, duration / 4, function () {
            match.freezeScreen(2, [dummy, camera]);
        }, { persistent: true });

        event.data.self.addTimer(10, 1, function () {
            victim.addEventListener(EntityEvent.COLLIDE_STRUCTURE, function (event: CharacterEvent) {
                camera.shake(10, 20);
            }, {});
        }, { persistent: true });

        event.data.self.addTimer(duration, 1, function () {
            camera.setMode(0);
            camera.deleteForcedTarget(victim);
            camera.addTarget(victim);
            dummy.dispose();
            Engine.forEach(match.getPlayers(), function (p: Character) {
                p.getDamageCounterContainer().alpha = 1;
                return true;
            }, []);
        }, { persistent: true });
    }
}



function toCriticalHit(event: GameObjectEvent) {
    event.data.hitboxStats.damage = event.data.hitboxStats.damage * 1.7;
    event.data.hitboxStats.knockbackGrowth = event.data.hitboxStats.knockbackGrowth + 10;
    var angle = event.data.hitboxStats.angle;


    if (GameObject.angleIsInSpikeThreshold(angle)) {
        event.data.hitboxStats.buryType = BuryType.PLUNGE;
    }
}

function applyKillSpark(hue: Int, owner: GameObject, angle: Int, duration: Int, scale: Int) {
    var vfx = match.createVfx(
        new VfxStats({ animation: "killSpark", spriteContent: getContent("vfx"), relativeWith: true, rotation: -angle })
        , owner);
    vfx.setScaleX(scale);
    vfx.setScaleY(scale);
    var filter: HsbcColorFilter = new HsbcColorFilter();
    filter.hue = Math.toRadians(hue);
    vfx.addFilter(filter);
    vfx.setX(owner.getX());
    vfx.setY(owner.getY());
    var NUM_DARKEN_COPIES = 4; // Multiple copies to darken the opacity
    var DARKEN_ALPHA = 1; // prolly shouldn't need to change this, unless u wanna super finetune
    for (curr_copy in 0...NUM_DARKEN_COPIES) {
        // Since fadeout is linear, might want to extend it a bit to keep things darker for longer,
        // Also pausing so it doesn't double fadeout
        var darkbg = match.createVfx(new VfxStats({ spriteContent: "global::vfx.vfx", animation: "vfx_parry_dust_behind", layer: VfxLayer.CHARACTERS_BACK, timeout: duration, fadeOut: true }), owner);
        darkbg.pause();
        darkbg.setAlpha(DARKEN_ALPHA);
    }
}

function increaseHitStop(event: GameObjectEvent) {
    event.data.hitboxStats.hitstopMultiplier = 3;
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
    return Random.getInt(1, 12) == 6;
}

function enableCriticalMode() {
    var players = match.getPlayers();
    Engine.forEach(players, function (player: Character, _idx: Int) {
        player.addEventListener(GameObjectEvent.HITBOX_CONNECTED, function (event: GameObjectEvent) {
            if (willCrit() || (match.getMatchSettingsConfig().matchRules[0].contentId == "infinitelives")) {
                toCriticalHit(event);
                player.addEventListener(GameObjectEvent.HIT_DEALT, zoomInOnFoe);
                player.addEventListener(GameObjectEvent.HIT_DEALT, function () {
                    var angle = event.data.hitboxStats.angle;
                    applyKillSpark(40, event.data.foe, angle, event.data.hitboxStats.hitstop + 20, 1.5);
                });

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
        player.updateCharacterStats({ grabAirType: GrabAirType.GRAB });
        player.addTimer(1, cancelWindow, function () {

            var currentAnimation = player.getAnimation();
            var usingSpecial = currentAnimation.substr(0, 7) == "special";
            var heldControls = player.getHeldControls();
            var side = heldControls.LEFT || heldControls.RIGHT;
            var up = heldControls.UP;
            var down = heldControls.DOWN;
            var neutral = !(up || down || side);
            var shield = heldControls.SHIELD || heldControls.SHIELD1 || heldControls.SHIELD_AIR || heldControls.SHIELD2;
            var special = heldControls.SPECIAL;
            var jump = heldControls.JUMP_ANY || heldControls.JUMP || heldControls.TAP_JUMP;

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
    // obj.addStatusEffect(StatusEffectType.ATTACK_SELF_HITSTOP_MULTIPLIER, 0);


    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_UP);
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_FORWARD);
    obj.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_DOWN);

    obj.updateCharacterStats({ airdashLimit: 0, shieldXOffset: 9999, shieldYOffset: 999 });

    obj.addTimer(2, -1, function () {
        obj.reactivateHitboxes();
    }, { persistent: true });


    obj.addEventListener(GameObjectEvent.HITBOX_CONNECTED, function (event: GameObjectEvent) {
        event.data.hitboxStats.hitEffectOverride = "";
        event.data.hitboxStats.stackKnockback = false;
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
        if ((obj.isFacingLeft() && pressingRight) || (obj.isFacingRight() && pressingLeft) && !obj.getState(CState.KO) && obj.getHitstun() == 0) {
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

function disableAllAttacks(player: Character) {
    //obj.getStatusEffectByType(StatusEffectType.)
    var tag = "ultimateAirDodge";
    var disabledActions = [
        CharacterActions.AERIAL_NEUTRAL,
        CharacterActions.AERIAL_FORWARD,
        CharacterActions.AERIAL_DOWN,
        CharacterActions.AERIAL_BACK,
        CharacterActions.AERIAL_UP,
        CharacterActions.SPECIAL_UP,
        CharacterActions.SPECIAL_DOWN,
        CharacterActions.SPECIAL_SIDE,
        CharacterActions.SPECIAL_NEUTRAL,
        CharacterActions.STRONG_DOWN,
        CharacterActions.STRONG_FORWARD,
        CharacterActions.STRONG_UP,
        CharacterActions.JAB,
        CharacterActions.TILT_FORWARD,
        CharacterActions.TILT_DOWN,
        CharacterActions.TILT_UP
    ];

    Engine.forEach(disabledActions, function (action: Int, _idx: Int) {
        player.addStatusEffect(StatusEffectType.DISABLE_ACTION, action, { tag: tag });
        return true;
    }, []);


}
function enableAirActions(player: Character, tag: String) {
    return function (event: GameObjectEvent) {
        var disabledStatus = player.findStatusEffectObjectsByTag(StatusEffectType.DISABLE_ACTION, tag);
        Engine.forEach(disabledStatus, function (effect: any, _idx: Int) {
            player.removeStatusEffect(StatusEffectType.DISABLE_ACTION, effect.id);
        }, []);
    }
}

// function normalizeAngle(hitboxStats: HitboxStats) {
//     hitboxStatsfa
// }


function distanceFromDeathBounds(entity: Entity, components) {
    var deathBounds = stage.getDeathBounds();
    var r = deathBounds.getRectangle();
    var width = r.width;
    var height = r.height;
    var top = deathBounds.getY(); // top
    var left = deathBounds.getX(); // left 
    var bottom = top + height; //  bottom
    var right = left + width; // right


    var entityX = entity.getX(); //
    var entityY = entity.getY(); //


    // Create points we can use to measure distance
    var topPoint = Point.create(0, top);
    var bottomPoint = Point.create(0, bottom);
    var leftPoint = Point.create(left, 0);
    var rightPoint = Point.create(right, 0);

    var entityXPoint = Point.create(entityX, 0);
    var entityYPoint = Point.create(0, entityY);

    var leftDistance = Math.abs(Math.getDistance(entityXPoint, leftPoint));
    var rightDistance = Math.abs(Math.getDistance(entityXPoint, rightPoint));
    var upDistance = Math.abs(Math.getDistance(entityYPoint, topPoint));
    var downDistance = Math.abs(Math.getDistance(entityYPoint, bottomPoint));

    var closestXBoundDistance = (if (components.x < 0) { leftDistance; } else { rightDistance; });
    var closestYBoundDistance = (if (components.y < 0) { upDistance; } else { downDistance; });
    return { x: closestXBoundDistance, y: closestYBoundDistance };

}


function calculateKnockback(victim: Character, stats: HitboxStats) {
    var percentage = victim.getDamage();
    var weight = victim.getGameObjectStat("weight");
    var damage = stats.damage;
    var base = stats.baseKnockback;
    var scaling = stats.knockbackGrowth / 100;
    var ratio = 1 / (5.57885284503643);
    var percentDamageExpr = (percentage / 10) + ((percentage * damage) / 20);
    var weightExpr = 1.4 * 200 / (weight + 100);
    var calculatedKnockback = ratio * ((((percentDamageExpr * weightExpr) + 18) * scaling) + base);
    return calculatedKnockback;
}


function finishZoom(event: GameObjectEvent) {
    var victim: Character = event.data.self;
    if (!victim.hasBodyStatus(BodyStatus.INVINCIBLE)) {
        var knockback = victim.getKnockback();
        var xVel = victim.getXKnockback();
        var yVel = victim.getYKnockback();

        var airTime = victim.getHitstun();
        // External Forces besides knockback
        var airFriction = victim.getGameObjectStat("aerialFriction");
        var gravity = victim.getGameObjectStat("gravity");

        var kbComponents = { x: xVel, y: yVel };
        var boundDistance: { x: Int, y: Int } = distanceFromDeathBounds(victim, kbComponents);
        var xDistance: Float = Math.abs(xVel * airTime) + 0.5 * (-airFriction * Math.pow(airTime, 2));
        var yDistance: Float =  if (kbComponents.y >= 0) {
            // "Calculating launch height using kinematic equations.");
            Math.abs((Math.abs(yVel) * airTime) + 0.5 * (gravity * Math.pow(airTime, 2)));
        } else {
            // "Calculating launch height using projectile motion formula.");
            Math.abs(Math.pow(yVel, 2) / (2.2 * (gravity)));
        };

        var distanceComponents = { x: xDistance, y: yDistance };
        var stats = event.data.hitboxStats;
        if (distanceComponents.x > boundDistance.x || distanceComponents.y > boundDistance.y || knockback > 35) {
            victim.addTimer(2, 3, function () {
                applyKillSpark(0, victim, stats.angle, 30, 1.5);
            }, { persistent: true });

            event.data.foe.forceStartHitstop(30, false);
            AudioClip.play(getContent("finishZoom"), { loop: false });
            victim.forceStartHitstop(30, true);
            zoomInOnSelf(event);

        }
    }

}

function enableActions(player: Character, tag: String) {
    return function (event: GameObjectEvent) {
        var disabledStatus = player.findStatusEffectObjectsByTag(StatusEffectType.DISABLE_ACTION, tag);
        Engine.forEach(disabledStatus, function (effect: any, _idx: Int) {
            player.removeStatusEffect(StatusEffectType.DISABLE_ACTION, effect.id);
        }, []);
    }
}


function disableActions(player: Character, tag: String) {
    //obj.getStatusEffectByType(StatusEffectType.)
    var disabledActions = [
        CharacterActions.AERIAL_NEUTRAL,
        CharacterActions.AERIAL_FORWARD,
        CharacterActions.AERIAL_DOWN,
        CharacterActions.AERIAL_BACK,
        CharacterActions.AERIAL_UP,
        CharacterActions.SPECIAL_UP,
        CharacterActions.SPECIAL_DOWN,
        CharacterActions.SPECIAL_SIDE,
        CharacterActions.SPECIAL_NEUTRAL,
        CharacterActions.STRONG_DOWN,
        CharacterActions.STRONG_FORWARD,
        CharacterActions.STRONG_UP,
        CharacterActions.JAB,
        CharacterActions.TILT_FORWARD,
        CharacterActions.TILT_DOWN,
        CharacterActions.TILT_UP
    ];

    Engine.forEach(disabledActions, function (action: Int, _idx: Int) {
        player.addStatusEffect(StatusEffectType.DISABLE_ACTION, action, { tag: tag });
        return true;
    }, []);
}



function performSpeedyFinalSmash(player: Character) {
    player.endAnimation();
    player.toState(CState.UNINITIALIZED);
    disableActions(player, "final_smash");
    player.playAnimation("assist_call");
    player.toggleGravity(false);
    player.setXSpeed(40);
    hitbox.updateHitboxStats(0, {
        damage: 20,
        baseKnockback: 0,
        knockbackGrowth: 0,
        hitstop: 120
    });

    var res = getContent("hitboxer");
    var hitbox: Projectile = match.createProjectile(res, self.getOwner());
    player.addTimer(30, 5, function () {
        hitbox.reactivateHitboxes();
        player.addTimer(1, 30, function () {
            hitbox.setX(player.getX());
            hitbox.setY(player.getY());
            player.setXSpeed(14);
            player.setYSpeed(ySpeed);

        }, { persistent: true, });
        player.flip();

    }, { persistent: true });

    player.addTimer(30 * 5, 1, function () {
        player.setXSpeed(0);
        player.toState(CState.STAND);
    }, { persistent: true });

}



function performFinalSmash(player: Character) {
    if (player.hasAnimation("final_smash")) {
        player.endAnimation();
        player.playAnimation("final_smash");
        player.playFrame(1);
        var port = player.getPlayerConfig().port;
        globalController.exports.data.finalSmashCharge[port] = 0;
    } else {
        // performSpeedyFinalSmash(player);
        Engine.log("No Placeholder Final Smash YET");
    }
}
function renderDamage(damage: Int,
    spriteResource: String,
    animation: String,
    spriteObjects: Array<{ sprite: Sprite, filter: HsbcColorFilter }>,
    container: Container,
    x: Int,
    y: Int,
    spaceBetween: Int) {

    if (spriteObjects == null) {
        spriteObjects = [];
    }

    var resource = spriteResource;
    var damageStr: String = "" + Math.floor(damage);
    var damageNums = [];
    Engine.forCount(damageStr.length, function (idx: Int) {
        damageNums.push(damageStr.charAt(idx));
        return true;
    }, []);



    var spaceBetween = spaceBetween;
    var maxLength = damageStr.length;

    var totalLength = maxLength;

    var untrimmed = (spriteObjects == null) ? 0 : (spriteObjects.length);
    if (untrimmed > 0) {
        Engine.forCount(untrimmed, function (idx: Int) {
            spriteObjects[idx].sprite.dispose();
            return true;
        }, []);
    }
    spriteObjects = spriteObjects.slice(untrimmed, spriteObjects.length);




    var greyScale: Bool = damage < 100 ? true : false;

    var makeSprite = function (pos: Int, animation: String) {
        var sprite: Sprite = Sprite.create(resource);
        var filter = new HsbcColorFilter();
        sprite.addFilter(filter);
        sprite.currentAnimation = animation;
        sprite.x = x + (spaceBetween) * (1 + pos);
        sprite.y = y;
        sprite.scaleX = 1;
        sprite.scaleY = 1;
        sprite.currentFrame = parseDigit(damageNums[pos]) + 1;
        return { sprite: sprite, filter: filter };
    }

    var insertSprite = function (sprite: { sprite: Sprite, filter: HsbcColorFilter }, pos: Int) {
        var frame = parseDigit(damageNums[pos]) + 1;

        if (greyScale) {
            sprite.filter.saturation = -1;
        } else {
            sprite.filter.saturation = 100;
        }

        if (spriteObjects[pos] == null) {
            spriteObjects[pos] = sprite;
            container.addChildAt(sprite.sprite, 0);
        } else {
            spriteObjects[pos].sprite.currentFrame = frame;
        }
    }

    var curr = 0;
    while (curr < maxLength) {
        var sprite = makeSprite(curr, animation);
        insertSprite(sprite, curr);
        curr++;
    }

    return spriteObjects;
}


var prevSprites = [];
function displayDamageNear(event: GameObjectEvent) {
    var player = event.data.self;
    var sprites = [];
    Engine.forEach(prevSprites, function (obj: { sprite: Sprite, filter: HsbcColorFilter }, _idx: Int) {
        var sprite = obj.sprite;
        sprite.dispose();
        return true;
    }, []);
    sprites = renderDamage(player.getDamage(),
        getContent("number"),
        "digits",
        sprites,
        stage.getCharactersContainer(),
        player.getX(),
        player.getY() + player.getEcbHeadY(), 32);
    prevSprites = sprites;
    Engine.forEach(sprites, function (obj: { sprite: Sprite, filter: HsbcColorFilter }, _idx: Int) {
        var sprite = obj.sprite;
        sprite.scaleX = 2;
        sprite.scaleY = 2;
        return true;
    }, []);
    var curr = 0;
    player.addTimer(1, 100, function () {
        Engine.forEach(sprites, function (obj: { sprite: Sprite, filter: HsbcColorFilter }, _idx: Int) {
            var sprite = obj.sprite;
            if (curr > 20) {
                sprite.alpha -= 0.02;
            }
            sprite.y -= 2;
            curr++;
            return true;

        }, []);
    }, { persistent: true });

    player.addTimer(101, 1, function () {
        Engine.forEach(sprites, function (obj: { sprite: Sprite, filter: HsbcColorFilter }, _idx: Int) {
            var sprite = obj.sprite;
            if (!sprite.isDisposed()) {
                sprite.dispose();
            }
            return true;
        }, []);
    }, { persistent: true });


}

function ultimateMode(player: Character) {
    var tag = "ultimateAirDodge";
    player.addEventListener(GameObjectEvent.HIT_RECEIVED, finishZoom, { persistent: true });
    player.addEventListener(GameObjectEvent.HIT_RECEIVED, displayDamageNear, { persistent: true });

    player.updateCharacterStats({ airdashInitialSpeed: 3, airdashSpeedCap: 6, airdashStartupLength: 1, airdashFullspeedLength: 30 });
    player.addEventListener(GameObjectEvent.LAND, enableAirActions(player, tag), { persistent: true });
    player.updateCharacterStats({ airdashTrailEffect: getContent("controller") });
    var neutralAirDash = function () {
        player.setXSpeed(0);
        player.setYSpeed(0);
    };
    var dodgeRollSpeed = player.getCharacterStat("dodgeRollSpeed");
    var jumps = player.getDoubleJumpCount();
    var sprites: Array<{ sprite: Sprite, filter: HsbcColorFilter }> = [];
    player.addTimer(1, -1, function () {
        var disabledStatus = player.findStatusEffectObjectsByTag(StatusEffectType.DISABLE_ACTION, tag);
        var heldControls = player.getHeldControls();
        var up = heldControls.UP;
        var down = heldControls.DOWN;
        var right = heldControls.RIGHT;
        var left = heldControls.LEFT;
        var shields = heldControls.SHIELD || heldControls.SHIELD1 || heldControls.SHIELD2;
        var neutral = !(up || left || down || right);
        var port = player.getPlayerConfig().port;
        var charge = globalController.exports.data.finalSmashCharge[port];
        if (player.getAnimation() != "final_smash"
            && hasMatchOrSubstring(actionable_animations, player.getAnimation())
            && player.getPressedControls().EMOTE
            && charge >= 251) {
            performFinalSmash(player);
        }

        if (neutral
            && shields
            && player.inStateGroup(CStateGroup.JUMP)
            && player.getHitstun() == 0
            && player.getHitstop() == 0) {
            player.setXSpeed(0.1);
            player.setYSpeed(-0.1);
            player.updateCharacterStats({ airdashSpeedCap: 0.001, airdashStartupLength: 0, airdashFullspeedLength: 40 });



        } else if (!player.inStateGroup(CStateGroup.AIRDASH)) {
            player.updateCharacterStats({ airdashSpeedCap: 6, airdashStartupLength: 3, airdashFullspeedLength: 30 });
        }
        if (player.inStateGroup(CStateGroup.AIRDASH)) {
            if (disabledStatus == null) {
                disableAllAttacks(player);
                if (neutral) {
                    player.resetMomentum();
                }
            }
        }
        if (player.isOnFloor()) {
            player.updateCharacterStats({ dodgeRollSpeed: dodgeRollSpeed });

        }

        if (player.inState(CState.AIRDASH_DECELERATING)) {
            player.setXSpeed(0);
            player.setYSpeed(0);
            player.resetMomentum();
            player.setDoubleJumpCount(0);

        }
        if (player.getPreviousState() == CState.AIRDASH_FULL_SPEED || player.getPreviousStateGroup(CStateGroup.AIRDASH)) {
            player.endAnimation();
            player.toState(CState.FALL);
            var gravity = player.getGameObjectStat("gravity");
            var dodgeTime = 25 / gravity;
            player.addTimer(dodgeTime, 1, function () {
                enableAirActions(player, tag)(null);
                player.setDoubleJumpCount(jumps);
            }, { persistent: true });

        }

        if (player.inStateGroup(CStateGroup.AIRDASH)) {
            player.updateAnimationStats({ bodyStatus: BodyStatus.INTANGIBLE });

        }


    }, { persistent: true });

}

function createFinalSmashMeter(player: Character) {
    var damageContainer = player.getDamageCounterContainer();
    var res = getContent("fsMeter");
    var sprite = Sprite.create(res);
    sprite.scaleX = 0.3;
    sprite.scaleY = 0.25;
    sprite.x = 64 + 32 + 8 + 12;
    sprite.y = 16 + 16 + 2;
    sprite.currentFrame = 0;
    damageContainer.addChild(sprite);
    var filter = new HsbcColorFilter();
    sprite.addFilter(filter);
    return {
        sprite: sprite,
        filter: filter
    }

}

function activateFinalSmashMeter(player: Character) {
    var port = player.getPlayerConfig().port;
    var spriteObj = globalController.exports.data.meters[port];
    var sprite: Sprite = spriteObj.sprite;
    var filter: HsbcColorFilter = spriteObj.filter;
    player.addTimer(1, -1, function () {
        var charge = globalController.exports.data.finalSmashCharge[port];
        if (charge >= 251) {
            filter.hue += 0.1;
        } else {
            filter.hue += 0.01;
        }


        if ((match.getMatchSettingsConfig().matchRules[0].contentId == "infinitelives")) {
            if (charge < 251) {
                globalController.exports.data.finalSmashCharge[port] += 1;
            } else {
                globalController.exports.data.finalSmashCharge[port] = 251;

            }
        }
        sprite.currentFrame = globalController.exports.data.finalSmashCharge[port];
    }, { persistent: true });
    player.addEventListener(GameObjectEvent.HIT_DEALT, function (event: GameObjectEvent) {
        var charge = globalController.exports.data.finalSmashCharge[port];
        if (player.getAnimation() != "final_smash" && !event.data.foe.hasBodyStatus(BodyStatus.INVINCIBLE)) {
            if (charge >= 251) {
                globalController.exports.data.finalSmashCharge[port] = 251;
            } else {
                globalController.exports.data.finalSmashCharge[port] += Math.ceil(event.data.hitboxStats.damage);
            }
        }

    }, { persistent: true });
}
function enableUltimateMode() {
    globalController.exports.data = {
        finalSmashCharge: [0, 0, 0, 0],
        meters: [null, null, null, null]
    };

    Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
        var port = player.getPlayerConfig().port;
        globalController.exports.data.meters[port] = createFinalSmashMeter(player);
        activateFinalSmashMeter(player);
        ultimateMode(player);
        return true;
    }, []);


}
function smash64Mode(player: Character) {
    player.addStatusEffect(StatusEffectType.ATTACK_HITSTUN_MULTIPLIER, 1.5);
    player.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.SPECIAL_SIDE);
    player.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.THROW_DOWN);
    player.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.THROW_UP);
    player.updateCharacterStats({ airdashLimit: 0, shieldScale: 0.008 });


    player.addTimer(1, -1, function () {
        if (player.inStateGroup(CStateGroup.ATTACK)) {
            switch (player.getState()) {
                case CState.STRONG_DOWN_CHARGE: {
                    player.toState(CState.STRONG_DOWN_ATTACK);
                };
                case CState.STRONG_UP_CHARGE: {
                    player.toState(CState.STRONG_UP_ATTACK);
                };
                case CState.STRONG_FORWARD_CHARGE: {
                    player.toState(CState.STRONG_FORWARD_ATTACK);
                };
                default: { };
            }
        }
        if (player.inState(CState.SPOT_DODGE)) {
            player.endAnimation();
            player.toState(CState.SHIELD_LOOP);
        }
    }, { persistent: true });

    player.addEventListener(GameObjectEvent.HITBOX_CONNECTED, function (event: GameObjectEvent) {
        event.data.hitboxStats.directionalInfluence = false;
    }, { persistent: true });
}

function enableSmash64() {
    Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
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


function getCoins(player: Character) {
    var port = player.getPlayerConfig().port;
    return globalController.exports.data.coins[port];

}

function setCoins(player: Character, coins: Int) {
    var port = player.getPlayerConfig().port;
    globalController.exports.data.coins[port] = Math.round(coins);
    var coinSprites = globalController.exports.data.coinSprites[port];
    refreshCoins(coinSprites, newCoins);

}
function addCoins(player: Character, coins: Int) {
    var port = player.getPlayerConfig().port;
    globalController.exports.data.coins[port] += coins;
    var coinSprites = globalController.exports.data.coinSprites[port];
    refreshCoins(coinSprites, newCoins);
}

function coinMode(player: Character) {
    var coinSprites = setupCoins(player);
    var port = player.getPlayerConfig().port;
    globalController.exports.data.coinSprites[port] = coinSprites;
    player.addEventListener(CharacterEvent.RESPAWN, function (event: CharacterEvent) {
        var target: Character = event.data.self;
        var coins = getCoins(target);
        var newCoins = Math.round(coins / 2);
        setCoins(target, newCoins);
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
    // var recalculatedTotal = (numBronze * 1) + (numSilver * 5) + (numGold * 10);
    var coinDamageListener = function (damage: Int) {
        return function (event: GameObjectEvent) {
            if (event.data.foe.getType() == EntityType.CHARACTER) {
                var foe: Character = event.data.foe;
                var foePort = foe.getPlayerConfig().port;
                globalController.exports.data.coins[foePort] += Math.round(damage);
                addCoins(player, damage);
                if (getCoins(foe) >= 9999) {
                    setCoins(foe, 9999);
                }
                event.data.self.destroy();
            }
        };
    }
    var goldListener = coinDamageListener(10);
    var silverListener = coinDamageListener(5);
    var bronzeListener = coinDamageListener(1);

    Engine.forCount(numGold, function (_idx: Int) {
        var proj = match.createProjectile(coinResource, player);
        proj.addEventListener(GameObjectEvent.HIT_DEALT, goldListener, { persistent: true });
        proj.playAnimation("gold");
        proj.setScaleX(4);
        proj.setScaleY(4);
    }, []);

    Engine.forCount(numSilver, function (_idx: Int) {
        var proj = match.createProjectile(coinResource, player);
        proj.addEventListener(GameObjectEvent.HIT_DEALT, silverListener, { persistent: true });
        proj.playAnimation("silver");
        proj.setScaleX(3);
        proj.setScaleY(3);
    }, []);
    Engine.forCount(numBronze, function (_idx: Int) {
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
        return players;
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
            } else if (hitLeftBlastZone) {
                player.setX(maxX - Math.abs(maxX * 0.2));
            } else if (hitUpBlastZone) {
                player.setY(maxY - Math.abs(maxY * 0.2));
            } else if (hitDownBlastZone) {
                player.setY(minY + Math.abs(minY * 0.2));
            }
        }, { persistent: true });

    }, []);
}

function createTimeObject(frames: Int) {
    var timeString = Engine.framesToTimeString(frames);
    var timeObj = parseTimeString(timeString);
    return timeObj;
}


function enableCoins() {
    globalController.exports.data = { coins: [0, 0, 0, 0], coinSprites: [[], [], [], []], spawnPositions: [{}, {}, {}, {}] };

    if (match.getMatchSettingsConfig().time > 0) {
        timeLeft.set(match.getMatchSettingsConfig().time * 60);
    }
    var p: Character = self.getOwner();
    var players = match.getPlayers();
    p.addTimer(70, 1, function () {
        var timeSprites = [];
        p.addTimer(1, -1, function () {
            timeLeft.dec();
            if (match.getMatchSettingsConfig().time == 0) {
                var frames = timeLeft.get();
                var timeObj = createTimeObject(frames);
                var ts = renderTime(timeObj, timeSprites, globalController.getViewRootContainer(), 0);
                var container = camera.getForegroundContainer();
                container.rotation = 0;
                container.addChildAt(globalController.getViewRootContainer(), 0);
                timeSprites = ts;
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
                        player.setLives(1);
                        player.addTimer(1, -1, function () {
                            if (player.getDamage() < 300) {
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

function renderTime(time, sprites: Array<Sprite>, container: Container, yOffset: Int) {
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
    sprites = sprites.slice(untrimmed, sprites.length);

    var makeSprite = function (frame: Int, pos: Int, animation: String) {
        var sprite: Sprite = Sprite.create(resource);
        var filter = new HsbcColorFilter();
        filter.hue = 25;
        sprite.addFilter(filter);
        sprite.currentAnimation = animation;
        sprite.x = 500 + (baseOffset) * (1 + pos);
        sprite.y = 32 + yOffset;
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


function regenBuff(player: Character, duration: Int) {
    var outerGlow = new GlowFilter();
    outerGlow.color = 0xff8c69;
    var innerGlow = new GlowFilter();
    innerGlow.color = 0xFFFFFF;
    player.addFilter(innerGlow);
    player.addFilter(outerGlow);

    var uid = player.addTimer(20, duration / 20, function () {
        player.addDamage(-1.5);
    }, { persistent: true });

    var removeBuff = function () {
        player.removeTimer(uid);
        player.removeFilter(innerGlow);
        player.removeFilter(outerGlow);
    }

    player.addEventListener(CharacterEvent.KNOCK_OUT, removeBuff, { persistent: true });
    player.addTimer(duration, 1, removeBuff, { persistent: true });
}

function mobilityBuff(player: Character, duration: Int) {
    var outerGlow = new GlowFilter();
    outerGlow.color = 0x00cc99;
    var innerGlow = new GlowFilter();
    innerGlow.color = 0xFFFFFF;
    player.addFilter(innerGlow);
    player.addFilter(outerGlow);
    var tag = "speedBuff";
    var jump = player.addStatusEffect(StatusEffectType.JUMP_SPEED_MULTIPLIER, 1.2, { tag: tag });
    var doubleJump = player.addStatusEffect(StatusEffectType.DOUBLE_JUMP_SPEED_MULTIPLIER, 1.2, { tag: tag });
    var fastFall = player.addStatusEffect(StatusEffectType.FAST_FALL_SPEED_MULTIPLIER, 1.2, { tag: tag });
    var runSpeed = player.addStatusEffect(StatusEffectType.RUN_SPEED_ACCELERATION_MULTIPLIER, 1.5, { tag: tag });
    var runSpeedCap = player.addStatusEffect(StatusEffectType.RUN_SPEED_CAP_MULTIPLIER, 1.5, { tag: tag });
    var dash = player.addStatusEffect(StatusEffectType.DASH_SPEED_MULTIPLIER, 1.5, { tag: tag });

    var removeBuff = function () {
        player.removeStatusEffect(StatusEffectType.RUN_SPEED_ACCELERATION_MULTIPLIER, runSpeed.id);
        player.removeStatusEffect(StatusEffectType.RUN_SPEED_CAP_MULTIPLIER, runSpeedCap.id);
        player.removeStatusEffect(StatusEffectType.DASH_SPEED_MULTIPLIER, dash.id);
        player.removeStatusEffect(StatusEffectType.JUMP_SPEED_MULTIPLIER, jump.id);
        player.removeStatusEffect(StatusEffectType.DOUBLE_JUMP_SPEED_MULTIPLIER, doubleJump.id);
        player.removeStatusEffect(StatusEffectType.FAST_FALL_SPEED_MULTIPLIER, fastFall.id);
        player.removeFilter(innerGlow);
        player.removeFilter(outerGlow);
    }

    player.addEventListener(CharacterEvent.KNOCK_OUT, removeBuff, { persistent: true });
    player.addTimer(duration, 1, removeBuff, { persistent: true });
}


function defenseBuff(player: Character, duration: Int) {
    var outerGlow = new GlowFilter();
    outerGlow.color = 0x00bfff;
    var innerGlow = new GlowFilter();
    innerGlow.color = 0xFFFFFF;
    player.addFilter(innerGlow);
    player.addFilter(outerGlow);

    var hitReceived = function (event: GameObjectEvent) {
        player.addDamage(-0.5 * event.data.hitboxStats.damage);
    };

    var removeBuff = function () {
        player.removeEventListener(GameObjectEvent.HIT_RECEIVED, hitReceived);
        player.removeFilter(innerGlow);
        player.removeFilter(outerGlow);
    }


    player.addEventListener(GameObjectEvent.HIT_RECEIVED, hitReceived, { persistent: true });
    player.addEventListener(CharacterEvent.KNOCK_OUT, removeBuff, { persistent: true });
    player.addTimer(duration, 1, removeBuff, { persistent: true });

}

function jumpCancels(player: Character, duration: Int) {
    var outerGlow = new GlowFilter();
    outerGlow.color = 0x000000;
    var innerGlow = new GlowFilter();
    innerGlow.color = 0xFFFFFF;
    player.addFilter(innerGlow);
    player.addFilter(outerGlow);
    var allowCancels = function (event: GameObjectEvent) {
        var player: Character = event.data.self;
        var cancelWindow = event.data.hitboxStats.hitstop + 10;
        var airborne = !player.isOnFloor();

        if (!player.inStateGroup(CStateGroup.GRAB)) {
            player.addTimer(1, cancelWindow, function () {
                var heldControls = player.getHeldControls();
                var jump = heldControls.JUMP_ANY || heldControls.JUMP || heldControls.TAP_JUMP;

                if (jump && airborne) {
                    player.setState(CState.JUMP_MIDAIR);
                } else if (jump && !airborne) {
                    player.setState(CState.JUMP_IN);
                }
            }, { persistent: true });
        }
    };
    player.addEventListener(GameObjectEvent.HIT_DEALT, allowCancels, { persistent: true });

    player.addTimer(duration, 1, function () {
        player.removeEventListener(GameObjectEvent.HIT_DEALT, allowCancels);
        player.removeFilter(innerGlow);
        player.removeFilter(outerGlow);
    }, { persistent: true });


}


function attackBuff(player: Character, duration: Int) {
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

    var disableBuff = function () {
        player.removeStatusEffect(StatusEffectType.HITBOX_DAMAGE_MULTIPLIER, damage.id);
        player.removeStatusEffect(StatusEffectType.ATTACK_HITSTUN_MULTIPLIER, hitstun.id);
        player.removeStatusEffect(StatusEffectType.ATTACK_KNOCKBACK_MULTIPLIER, knockback.id);
        player.removeFilter(innerGlow);
        player.removeFilter(outerGlow);
    }

    player.addEventListener(CharacterEvent.KNOCK_OUT, disableBuff, { persistent: true });
    player.addTimer(duration, 1, disableBuff, { persistent: true });
}


function getMissionStatus(player: Character) {
    var port = player.getPlayerConfig().port;
    return globalController.exports.data.missionStatus[port];
}


function createMissionStatus(player: Character) {
    var port = player.getPlayerConfig().port;
    var container: Container = player.getDamageCounterContainer();
    var resource: String = getContent("missionStatus");
    var sprite = Sprite.create(resource);
    sprite.y = sprite.y + 10;
    sprite.x = sprite.x + (8);
    sprite.scaleX = 0.6;
    sprite.scaleY = 0.6;
    sprite.alpha = 1;
    container.addChildAt(sprite, 999);
    globalController.exports.data.missionStatusSprites[port] = sprite;

}

function refreshMissionStatus(player: Character) {
    var port = player.getPlayerConfig().port;
    var sprite: Sprite = globalController.exports.data.missionStatusSprites[port];

    switch (getMissionStatus(player)) {
        case MISSION_PENDING: sprite.currentAnimation = "pending";
        case MISSION_FAIL: sprite.currentAnimation = "fail";
        case MISSION_SUCCESS: sprite.currentAnimation = "success";
        default: sprite.currentAnimation = "empty";
    }
}

function setMissionStatus(player: Character, status: Int) {
    var port = player.getPlayerConfig().port;
    globalController.exports.data.missionStatus[port] = status;
    refreshMissionStatus(player);
}

function landStrongs(times: Int, duration: Int) {
    var players: Array<Character> = match.getPlayers();
    Engine.forEach(players, function (player: Character, _idx: Int) {
        var prevTime = match.getElapsedFrames();
        var count = [0];
        var hitDealt = function (event: GameObjectEvent) {
            var attacker: Character = event.data.self;
            var currTime = match.getElapsedFrames();
            if (
                (attacker.inState(CState.STRONG_FORWARD_ATTACK)
                    || attacker.inState(CState.STRONG_DOWN_ATTACK)
                    || attacker.inState(CState.STRONG_UP_ATTACK))
                && (currTime - prevTime) > 100) {
                prevTime = currTime;
                count[0] += 1;
                if (count[0] >= times) {
                    setMissionStatus(player, MISSION_SUCCESS);
                }
            }
        };

        player.addEventListener(GameObjectEvent.HIT_DEALT, hitDealt, { persistent: true });
        player.addTimer(duration, 1, function () {
            player.removeEventListener(GameObjectEvent.HIT_DEALT, hitDealt);
            if (count[0] >= times) {
                setMissionStatus(player, MISSION_SUCCESS);
            } else {
                setMissionStatus(player, MISSION_FAIL);
            }
        }, { persistent: true });

    }, []);


}
function noHit(duration: Int) {
    var players: Array<Character> = match.getPlayers();

    Engine.forEach(players, function (player: Character, _idx: Int) {
        var req = function (event: GameObjectEvent) {
            if (event.data.hitboxStats.damage > 0) {
                setMissionStatus(event.data.self, MISSION_FAIL);
            }
        };

        player.addEventListener(GameObjectEvent.HIT_RECEIVED, req, { persistent: true });

        player.addTimer(duration - 5, 1, function () {
            if (getMissionStatus(player) != MISSION_FAIL) {
                setMissionStatus(player, MISSION_SUCCESS);
            }

            player.removeEventListener(GameObjectEvent.HIT_RECEIVED, req);
        }, { persistent: true });
        return true;
    }, []);
}

function landedParry(duration: Int) {
    var players: Array<Character> = match.getPlayers();

    Engine.forEach(players, function (player: Character, _idx: Int) {
        var req = function (event: ScoreEvent) {
            setMissionStatus(event.data.self, MISSION_SUCCESS);
        };

        match.addEventListener(ScoreEvent.PARRY, req, { persistent: true });

        player.addTimer(duration - 5, 1, function () {
            if (getMissionStatus(player) != MISSION_SUCCESS) {
                setMissionStatus(player, MISSION_FAIL);
            }
            match.removeEventListener(ScoreEvent.PARRY, req);


        }, { persistent: true });
        return true;
    }, []);
}

function landedSpikes(count: Int, duration: Int) {
    var players: Array<Character> = match.getPlayers();
    Engine.forEach(players, function (player: Character, _idx: Int) {
        var i = [0];
        var req = function (event: GameObjectEvent) {
            if (GameObject.angleIsInSpikeThreshold(event.data.hitboxStats.angle)) {
                i[0] += 1;
            }
            if (i[0] >= count) {
                setMissionStatus(player, MISSION_SUCCESS);
            }
        };
        player.addEventListener(GameObjectEvent.HIT_DEALT, req, { persistent: true });
        player.addTimer(duration - 5, 1, function () {
            if (getMissionStatus(player) != MISSION_SUCCESS) {
                setMissionStatus(player, MISSION_FAIL);
            }
            player.removeEventListener(GameObjectEvent.HIT_DEALT, req);
        }, { persistent: true });
        return true;
    }, []);
}

function dealDamage(duration: Int, damage: Int) {

    var players: Array<Character> = match.getPlayers();

    Engine.forEach(players, function (player: Character, _idx: Int) {
        var port = player.getPlayerConfig().port;
        globalController.exports.data.missionData[port] = { damage: 0 };

        var addDamage = function (event: GameObjectEvent) {
            var player: Character = event.data.self;
            var port: Int = player.getPlayerConfig().port;

            globalController.exports.data.missionData[port].damage += event.data.hitboxStats.damage;
            if (globalController.exports.data.missionData[port].damage >= damage && getMissionStatus(player) != MISSION_FAIL) {
                setMissionStatus(player, MISSION_SUCCESS);
            }
        }
        player.addEventListener(GameObjectEvent.HIT_DEALT, addDamage, { persistent: true });
        player.addTimer(duration - 5, 1, function () {
            player.removeEventListener(GameObjectEvent.HIT_DEALT, addDamage);
            if (getMissionStatus(player) != MISSION_SUCCESS) {
                setMissionStatus(player, MISSION_FAIL);
            }
        }, { persistent: true });
        return true;
    }, []);

}

function clearMissionData() {
    globalController.exports.data.missionStatus = [MISSION_PENDING, MISSION_PENDING, MISSION_PENDING, MISSION_PENDING];
    Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
        setMissionStatus(player, MISSION_PENDING);
        return true;
    }, []);
    globalController.exports.data.missionData = [{}, {}, {}, {}];
}

function displayMissionPrompt(mission: String) {

    var missionPrompt: Sprite = Sprite.create(getContent("missionPrompt"));
    missionPrompt.x = Math.abs(stage.getCameraBounds().getX() / 2.75);
    missionPrompt.y = Math.abs(stage.getCameraBounds().getY() / 2);
    missionPrompt.scaleX = 3;
    missionPrompt.scaleY = 3;
    missionPrompt.currentAnimation = mission;
    var dummy: Projectile = match.createProjectile(getContent("dummyProj"), null);
    globalDummy = dummy;

    dummy.setScaleX(0.1);
    dummy.setScaleY(0.1);

    camera.getForegroundContainer().addChild(missionPrompt);
    var totalFrames = missionPrompt.totalFrames * 2;
    var curr = 0;
    match.freezeScreen(totalFrames * 2, [self, dummy]);
    dummy.addTimer(2, totalFrames * 2, function () {
        curr += 1;
        if (missionPrompt.currentAnimation == mission && missionPrompt.currentFrame < missionPrompt.totalFrames) {
            missionPrompt.currentFrame += 1;
        } else if (curr == totalFrames) {
            missionPrompt.currentAnimation = "empty";
        } else if (curr == totalFrames) {
            missionPrompt.dispose();
        }

    }, { persistent: true });

    return (totalFrames * 2);
}

function generateMission(displayString: String, missionFn, duration: Int, rewardFn) {
    return {
        displayString: displayString,
        missionFn: missionFn,
        duration: duration,
        rewardFn: rewardFn
    }
}

function runMission(mission) {
    var p: Character = self.getOwner();
    globalController.exports.data.cooldown = true;
    displayMissionPrompt(mission.displayString);
    clearMissionData();
    mission.missionFn();
    var timeSprites = [];
    var curr = 0;

    p.addTimer(1, mission.duration, function () {
        curr += 1;
        var ts = renderTime(createTimeObject(mission.duration - curr), timeSprites, globalController.getViewRootContainer(), 32);
        var container = camera.getForegroundContainer();
        container.addChildAt(globalController.getViewRootContainer(), 0);
        timeSprites = ts;
    }, { persistent: true });

    p.addTimer(mission.duration, 1, function () {
        globalDummy.destroy();

        Engine.forEach(timeSprites, function (sprite: Sprite, _idx: Int) {
            sprite.dispose();
            return true;
        }, []);

        Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
            if (getMissionStatus(player) == MISSION_SUCCESS) {
                mission.rewardFn(player);
            }
            return true;
        }, []);

        p.addTimer(60 * 35, 1, function () {
            clearMissionData();
            globalController.exports.data.cooldown = false;
        }, { persistent: true });

    }, { persistent: true });

    var totalMissionTime = mission.duration;
    return totalMissionTime;
}


function enableMissionMode() {
    globalController.exports.data = {
        missionStatus: [MISSION_PENDING, MISSION_PENDING, MISSION_PENDING, MISSION_PENDING],
        missionData: [{}, {}, {}, {}],
        missionStatusSprites: [null, null, null, null],
        cooldown: false
    };


    var p: Character = self.getOwner();
    var players: Character = match.getPlayers();

    Engine.forEach(players, function (player: Character, _idx: Int) {
        createMissionStatus(player);
        player.addEventListener(CharacterEvent.KNOCK_OUT, function (event: CharacterEvent) {
            if (getMissionStatus(player) != MISSION_SUCCESS) {
                setMissionStatus(player, MISSION_FAIL);
            }
        }, { persistent: true });
        return true;
    }, []);
    clearMissionData();



    var deal50Regen = generateMission("deal50Regen",
        function () { dealDamage(60 * 20, 50); },
        60 * 20,
        function (player: Character) { regenBuff(player, 60 * 10); });

    var noHitDefense = generateMission("noHitDefense",
        function () { noHit(60 * 15); },
        60 * 15,
        function (player: Character) { defenseBuff(player, 60 * 10); });

    var landStrongMobility = generateMission("landStrongMovement",
        function () { landStrongs(4, 60 * 20); },
        60 * 20,
        function (player: Character) { mobilityBuff(player, 60 * 10); });


    var landedParryCancel = generateMission("parryJumpCancel",
        function () { landedParry(60 * 15); },
        60 * 15,
        function (player: Character) { jumpCancels(player, 60 * 10); });

    var landedSpikes = generateMission("spikeAttackBoost",
        function () { landedSpikes(3, 60 * 15); },
        60 * 15,
        function (player: Character) { attackBuff(player, 60 * 10); });

    var missions = [noHitDefense, deal50Regen, landedParryCancel, landStrongMobility, landedSpikes];


    p.addTimer(60, -1, function () {
        if (globalController.exports.data.cooldown == false) {
            var chosenMission = Random.getChoice(missions);
            runMission(chosenMission);
        }
    }, { persistent: true });

}



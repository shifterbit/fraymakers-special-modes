
// DO NOT TOUCH
var actionable_animations: Array<String> = [
    "parry_success",
    "stand", "stand_turn", "idle",
    "walk", "walk_in", "walk_out", "walk_loop",
    "run", "run_turn", "skid",
    "jump_squat", "jump_in", "jump_out", "jump_midair", "jump_loop",
    "fall_loop", "fall_in", "fall_out",
    "crouch_loop", "crouch_in", "crouch_out",
    "dash", "airdash_land", "emote", "fall"
];
var enabled = self.makeBool(false);
var prefix = "specialModeType_";
var STATUS_TAG = "_specialModeStatusTag";
var globalMode = "none";
var timeLeft = self.makeInt(60 * 60 * 5);
var globalController: CustomGameObject = null;
var slowDown: { user: GameObject, timer: Int } = null;
var MISSION_FAIL = -1;
var MISSION_SUCCESS = 1;
var MISSION_PENDING = 0;
var FINAL_SMASH_CHARGE = 500;
var PARRY_WINDOW = 10;
var ULTIMATE_VARIANT = 0;
var GENERIC_VARIANT = 1;
var SMASH64_VARIANT = 2;
var state: ApiVarObject = self.makeObject({
    players: [{}, {}, {}, {}]
});
var noShielders = [
    "cc_3040908417::SSF2DK.SSF2DK"
];


var allActions = [
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
    CharacterActions.TILT_UP,
    CharacterActions.DASH_ATTACK,
    CharacterActions.THROW_BACK,
    CharacterActions.THROW_DOWN,
    CharacterActions.THROW_FORWARD,
    CharacterActions.THROW_BACK,
    CharacterActions.CRASH_ATTACK,
    CharacterActions.LEDGE_ATTACK,
];







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
    "mission",
    "ultimate"
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

function genericDispose(obj: GameObject, timers: Array<Int>, events: Array<Array<Any>>) {
    for (timer in timers) {
        obj.removeTimer(timer);
    }

    for (event in events) {
        obj.removeEventListener(event[0], event[1]);
    }
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
    var player: Character = self.getOwner();

    var text = globalMode + "\nmode";
    var emptyVfx = match.createVfx(new VfxStats({
        x: 150,
        y: 22,
        loop: true,
        animation: "empty",
        spriteContent: getContent("text")
    }), null);
    var inner = emptyVfx.getViewRootContainer();

    var container: Container = player.getDamageCounterContainer();

    var textSprites = [];

    var textData = renderText(text, textSprites, inner, {
        x: 0,
        y: 0,
        spacebetween: 2,

    });
    Engine.forEach(textData.sprites, function (sprite: Sprite, idx: int) {
        var glow = new GlowFilter();
        glow.color = 0x1e1e1e;
        glow.radius = 0.6;
        sprite.addFilter(glow);
        if (idx < globalMode.length) {
            sprite.x -= (globalMode.length * 8);
        } else {
            sprite.x -= (4 * 8);

        }
        return true;
    }, []);
    inner.scaleX = 0.7;
    inner.scaleY = 0.7;



    container.addChild(inner);


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
            case ("ultimate"): { enableUltimateMode(); }
            default: { };
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

function customComboMode(player: Character, duration: Int) {
    function _mTurbo() {
        var pressed = player.getPressedControls();
        if (pressed.ATTACK) {
            if (pressed.STRONG) {
                directionToStrong(player);
            } else {
                directionToNormal(player);
            }
        }
        if (pressed.SPECIAL) {
            directionToSpecial(player);
        }
        player.preLand();
    }
    player.addEventListener(GameObjectEvent.HIT_DEALT, _mTurbo, { persistent: true });

    function remove() {
        player.removeEventListener(GameObjectEvent.HIT_DEALT, _mTurbo);
    }

    player.addTimer(duration, 1, function () {
        remove();
    }, { persistent: true });

    return remove;
}

function turbo(player: Character) {
    function hitDealt() {
        player.updateAnimationStats({ interruptible: true });

    }
    player.addEventListener(GameObjectEvent.HIT_DEALT, hitDealt, { persistent: true });
    events = [[GameObjectEvent.HIT_DEALT, hitDealt]];


    // p.addEventListener(EntityEvent.STATE_CHANGE, function change() {
    //     p.removeEventListener(EntityEvent.STATE_CHANGE,change);

    // }, {persistent: true});
    return {
        dispose: function () { genericDispose(player, [], events); }
    }
}

function enableTurboMode() {
    var players = match.getPlayers();
    Engine.forEach(players, function (player: Character, _idx: Int) {
        turbo(player);
        return true;
    }, []);
}

function slowMotion(duration: Int, persistent: Bool) {

    if (slowDown != null) {
        slowDown.user.removeTimer(slowDown.timer);
    }
    var timer = self.getOwner().addTimer(4, 4, function () {
        match.freezeScreen(2, [self, camera]);
    }, { persistent: persistent });
    slowDown = { user: self.getOwner(), timer: timer };
}

function zoomInOnPlayer(target: GameObject, duration: Int) {
    if (!target.hasBodyStatus(BodyStatus.INVINCIBLE)) {
        var target: Character = target;
        camera.addForcedTarget(target);
        camera.setMode(1);

        Engine.forEach(match.getPlayers(), function (p: Character) {
            p.getDamageCounterContainer().alpha = 0;
            return true;
        }, []);

        target.addTimer(10, 1, function () {
            target.addEventListener(EntityEvent.COLLIDE_STRUCTURE, function (event: CharacterEvent) {
                camera.shake(10, 20);
            }, {});
        }, { persistent: true });

        target.addTimer(duration, 1, function () {
            camera.setMode(0);
            camera.deleteForcedTarget(target);
            camera.addTarget(target);
            Engine.forEach(match.getPlayers(), function (p: Character) {
                if (p.getLives() != 0 || match.getMatchSettingsConfig().lives == -1) {
                    camera.addTarget(p);
                }
                p.getDamageCounterContainer().alpha = 1;
                return true;
            }, []);
        }, { persistent: true });
    }
}




function toCriticalHit(event: GameObjectEvent) {
    event.data.hitboxStats.damage = event.data.hitboxStats.damage * 1.7;
    event.data.hitboxStats.knockbackGrowth = event.data.hitboxStats.knockbackGrowth + 10;
    event.data.hitboxStats.hitstop = event.data.hitboxStats.hitstop + 10;
    event.data.hitboxStats.selfHitstop = event.data.hitboxStats.selfHitstop + 10;

    var angle = event.data.hitboxStats.angle;



    if (GameObject.angleIsInSpikeThreshold(angle)) {
        event.data.hitboxStats.buryType = BuryType.PLUNGE;
    }
}

function applyKillSpark(hue: Int, owner: GameObject, angle: Int, scale: Int, vfxOwner: GameObject) {
    var vfx = match.createVfx(
        new VfxStats({
            animation: "killSpark",
            spriteContent: self.getResource().getContent("vfx"),
            rotation: -angle,
            scaleX: scale, scaleY: scale
        })
        , vfxOwner);

    var filter: HsbcColorFilter = new HsbcColorFilter();
    filter.hue = Math.toRadians(hue);
    vfx.addFilter(filter);
    vfx.setX(owner.getX());
    vfx.setY(owner.getY());
    return vfx;
}

function darkenScreen(duration: Int, strength: Int) {
    var NUM_DARKEN_COPIES = strength; // Multiple copies to darken the opacity
    var DARKEN_ALPHA = 1; // prolly shouldn't need to change this, unless u wanna super finetune
    var garbage: Array<Vfx> = [];

    for (curr_copy in 0...NUM_DARKEN_COPIES) {
        // Since fadeout is linear, might want to extend it a bit to keep things darker for longer,
        // Also pausing so it doesn't double fadeout
        var darkbg = match.createVfx(new VfxStats({ spriteContent: "global::vfx.vfx", animation: "vfx_parry_dust_behind", layer: VfxLayer.CHARACTERS_BACK, timeout: duration, fadeOut: true }), null);
        darkbg.pause();
        darkbg.setAlpha(DARKEN_ALPHA);
        garbage.push(darkbg);
    }
    var owner: Character = self.getOwner();
    owner.addTimer(duration, 1, function () {
        Engine.forEach(garbage, function (vfx: Vfx, idx: Int) {
            vfx.destroy();
            return true;
        }, []);
    }, { persistent: true });
}

function increaseHitStop(event: GameObjectEvent) {
    event.data.hitboxStats.hitstopOffset = 10;
    event.data.hitboxStats.selfHitstopOffset = 10;
}
function dramatic(obj: GameObject) {
    var events = [];
    var timers = [];
    function hitDealt(event: GameObjectEvent) {
        var stats = event.data.hitboxStats;
        zoomInOnPlayer(event.data.foe, stats.selfHitstop);
        slowMotion(stats.selfHitstop, false);
    }
    function projectileCreated(e: GameObjectEvent) {
        dramatic(e.data.other);
    }
    obj.addEventListener(GameObjectEvent.PROJECTILE_CREATED, projectileCreated, { persistent: true });
    obj.addEventListener(GameObjectEvent.HIT_DEALT, hitDealt, { persistent: true });
    obj.addEventListener(GameObjectEvent.HITBOX_CONNECTED, increaseHitStop, { persistent: true });
    events.push([GameObjectEvent.PROJECTILE_CREATED, projectileCreated]);
    events.push([GameObjectEvent.HIT_DEALT, hitDealt]);
    events.push([GameObjectEvent.HITBOX_CONNECTED, increaseHitStop]);

    return {
        dispose: function () { genericDispose(obj, timers, events); }
    }
}

function enableDramaticMode() {
    var players = match.getPlayers();

    Engine.forEach(players, function (player: Character, _idx: Int) {
        dramatic(player);
        return true;
    }, []);
}


function willCrit() {
    return match.getElapsedFrames() % Random.getInt(1, 16) == 0;
}


function criticalHit(obj: GameObject) {
    var events = [];
    var timers = [];
    var crit = false;
    function projectileCreated(e: GameObjectEvent) {
        criticalHit(e.data.other);
    }
    function hitDealt(event: GameObjectEvent) {
        var stats = event.data.hitboxStats;
        if (!(event.data.foe.hasBodyStatus(BodyStatus.INVINCIBLE))
            && (crit
                || (match.getMatchSettingsConfig().matchRules[0].contentId == "infinitelives"))) {
            zoomInOnPlayer(event.data.foe, stats.selfHitstop);
            slowMotion(stats.selfHitstop, true);
            applyKillSpark(40, event.data.foe, stats.angle, 1, event.data.foe);
            darkenScreen(stats.selfHitstop + 15, 10);
        }
    }

    function hitConnected(event: GameObjectEvent) {
        if (crit || (match.getMatchSettingsConfig().matchRules[0].contentId == "infinitelives")) {
            toCriticalHit(event);
        }
    }
    obj.addEventListener(GameObjectEvent.PROJECTILE_CREATED, projectileCreated, { persistent: true });
    obj.addEventListener(GameObjectEvent.HIT_DEALT, hitDealt, { persistent: true });
    obj.addEventListener(GameObjectEvent.HITBOX_CONNECTED, hitConnected, { persistent: true });

    events.push([GameObjectEvent.PROJECTILE_CREATED, projectileCreated]);
    events.push([GameObjectEvent.HIT_DEALT, hitDealt]);
    events.push([GameObjectEvent.HITBOX_CONNECTED, hitConnected]);


    timers.push(obj.addTimer(1, -1, function () {
        crit = willCrit();
    }, { persistent: true }));


    return {
        dispose: function () { genericDispose(obj, timers, events); }
    }
}

function enableCriticalMode() {
    var players = match.getPlayers();
    Engine.forEach(players, function (player: Character, _idx: Int) {
        criticalHit(player);
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
            player.preLand(false);
        }
        player.updateCharacterStats({ grabAirType: GrabAirType.GRAB });
        player.addTimer(1, cancelWindow, function () {

            var currentAnimation = player.getAnimation();
            var usingSpecial = currentAnimation.substr(0, 7) == "special";
            var held = player.getHeldControls();
            var pressed = player.getPressedControls();

            var jump = pressed.JUMP_ANY;

            if (!usingSpecial && pressed.SPECIAL) {
                directionToSpecial(player);
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


function ssf1Mode(player: Character) {
    player.addStatusEffect(StatusEffectType.GROUND_FRICTION_MULTIPLIER, 0.3);
    player.addStatusEffect(StatusEffectType.AERIAL_FRICTION_MULTIPLIER, 0.07);
    player.addStatusEffect(StatusEffectType.ATTACK_HITSTOP_MULTIPLIER, 0);
    player.addStatusEffect(StatusEffectType.ATTACK_SELF_HITSTOP_MULTIPLIER, 0);
    player.addStatusEffect(StatusEffectType.ATTACK_HITSTUN_MULTIPLIER, 0);

    player.updateCharacterStats({ airdashLimit: 0, shieldXOffset: 99999, shieldYOffset: 9999 });

    player.addTimer(2, -1, function () {
        player.reactivateHitboxes();
    }, { persistent: true });


    player.addEventListener(GameObjectEvent.HITBOX_CONNECTED, function (event: GameObjectEvent) {
        event.data.hitboxStats.hitEffectOverride = "";
        event.data.hitboxStats.stackKnockback = false;
    }, { persistent: true });

    player.addEventListener(EntityEvent.STATE_CHANGE, function (event: EntityEvent) {
        var toState = event.data.toState;
        if (
            toState == CState.SHIELD_IN
            || toState == CState.SHIELD_AIR
            || toState == CState.AIRDASH_INITIAL
            || toState == CState.GRAB
            || toState == CState.PARRY_IN
            || toState == CState.STRONG_DOWN_IN
            || toState == CState.STRONG_FORWARD_IN
            || toState == CState.STRONG_UP_IN) {
            directionToNormal(player);
        }
    }, { persistent: true });


    player.addTimer(0.5, -1, function () {
        player.setAirdashCount(0);
        var grounded = player.isOnFloor();

        var pressingRight = player.getHeldControls().RIGHT;
        var pressingLeft = player.getHeldControls().LEFT;
        if ((player.isFacingLeft() && pressingRight) || (player.isFacingRight() && pressingLeft) && !player.getState(CState.KO) && player.getHitstun() == 0) {
            player.flipX(player.getX());
            if (player.isFacingLeft()) {
                player.faceRight();
            } else if (player.isFacingRight()) {
                player.faceLeft();
            }
            if (grounded) {
                player.resetMomentum();
                if (player.inStateGroup(CStateGroup.WALK)) {
                    player.toState(CState.WALK_LOOP);
                } else if (player.getState() == CState.RUN || player.getState() == CState.DASH) {
                    player.toState(CState.DASH);
                } else {
                    player.endAnimation();
                    player.toState(CState.WALK_LOOP);
                }
            } else {
                player.toState(CState.FALL);
            }

        }
    }, { persistent: true });
}

function enableSSF1Mode() {
    Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
        ssf1Mode(player);
        return true;
    }, []);

    disableLedges();
    disablePlatDrops();

}

function disableLedges() {
    Engine.forEach(match.getStructures(), function (structure: Structure, _idx: Int) {
        structure.updateStructureStats({ leftLedge: false, rightLedge: false });
        return true;
    }, []);
}
function disablePlatDrops() {
    Engine.forEach(match.getStructures(), function (structure: Structure, _idx: Int) {
        structure.updateStructureStats({ dropThrough: false });
        return true;
    }, []);
}

function hexToRGB(hex: Int): { r: Int, g: Int, b: Int } {
    var r = (hex >> 16) & 0xFF;
    var g = (hex >> 8) & 0xFF;
    var b = hex & 0xFF;
    return {
        r: r,
        g: g,
        b: b,
    }
}


function toGreyScale(hex: Int) {
    var rgba = hexToRGB(hex);
    var newAverage = (rgba.r + rgba.b + rgba.g) / 3;
    var newHex = (1 << 24) + (newAverage << 16) + (newAverage << 8) + (newAverage);
    return newHex;
}


function greyScalePlayer(player: Character) {
    var paletteMap: IntMap = player.getCostumeShader().paletteMap;
    for (key in paletteMap.keys()) {
        paletteMap.set(key, toGreyScale(paletteMap.get(key)));
    }

}

function clonePallete(player: Character) {
    var v = new IntMap();
    var oldMap = player.getCostumeShader().paletteMap;
    for (key in oldMap.keys()) {
        v.set(key, oldMap.get(key));
    }
    return v;

}

function enableMVSMode() {
    disableLedges();
    Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
        // var clonedMap = clonePallete(player);
        // greyScalePlayer(player);
        // var currMap = player.getCostumeShader().paletteMap;
        // var colorShader = createColorShader(0xfcc200);
        // player.addShader(colorShader);
        // player.addTimer(120, 1, function () {
        //     player.removeShader(colorShader);
        //     for (key in currMap) {
        //         currMap.set(key, clonedMap.get(key));
        //     }
        // }, { persistent: true });

        // mvsMode(player);
        player.addEventListener(EntityEvent.STATE_CHANGE, function (e: EntityEvent) {
            var toState: Int = e.data.toState;
            if (toState == CState.AIRDASH_INITIAL || toState == CState.AIRDASH_ACCELERATING) {
                uniAssault(player);
            }
        }, { persistent: true });

        return true;
    }, []);
}

function playWallJump(player: Character) {
    //When the player wall jumps, essentially perform a ledge jump (but with the wall jump animation)
    player.resetMomentum();
    if (player.hasAnimation("wall_jump")) {
        player.playAnimation("wall_jump");
    } else {
        player.playAnimation("jump_in");
    }
    player.setXVelocity(1.5 * player.flipX(player.getCharacterStat("ledgeJumpXSpeed")));
    player.setYVelocity(player.getCharacterStat("ledgeJumpYSpeed"));

}

function superPreland(player: Character) {
    player.setAirdashCount(player.getGameObjectStat("airdashLimit"));
    player.preLand(false);
    if (player.inState(CState.FALL_SPECIAL) || player.getAnimation() == "fall_special") {
        player.toState(CState.FALL);
    }
}

function enableWallJumps(player: Character) {
    player.addTimer(1, -1, function () {
        var held = player.getHeldControls();
        var ecb = player.getEcbCollisionBox();
        var leftHipPoint = Point.create(player.getX() - 5, player.getY() + player.getEcbLeftHipY());
        var rightHipPoint = Point.create(player.getX() + ecb.width + 5, player.getY() + player.getEcbLeftHipY());
        var result = Point.create(1);
        var rightWalls = player.hitTestStructuresWithLineSegment(leftHipPoint, rightHipPoint, result, { structureType: StructureType.RIGHT_WALL });
        var leftWalls = player.hitTestStructuresWithLineSegment(leftHipPoint, rightHipPoint, result, { structureType: StructureType.LEFT_WALL });
        if (held.JUMP_ANY) {
            if (leftWalls != null) {
                player.faceLeft();
                playWallJump(player);
            } else if (rightWalls != null) {
                player.faceRight();
                playWallJump(player);
            }
        }
    }, { persistent: true });

}

function mvsModeOnStateChange(e) {

}

function performAirdodge(player: Character, variant: Int) {
    player.resetMomentum();
    player.setXVelocity(0);
    player.setYVelocity(0);
    if (player.isOnFloor()) {
        player.setYVelocity(-1);
    }

    var vector = getAirDodgeAngle(player, Math.min(10, player.getCharacterStat("airdashSpeedCap")));
    var movingSpeed = vector.movingSpeed;
    var angle = vector.angle;

    var bdpgoinFast = "cc_3380358897::bdpgoinfast.bdpgoinfast";
    var animation = "spot_dodge";
    if (player.getGameObjectStat("spriteContent") == bdpgoinFast) {
        animation = "spot_dodge";
        if (movingSpeed > 1) {
            animation = "special_down_jump";
        }
    }

    player.toState(CState.EMOTE, animation);
    player.updateAnimationStats({ endType: AnimationEndType.NONE, allowMovement: false, });
    player.updateAnimationStats({ bodyStatus: BodyStatus.INTANGIBLE });
    player.toggleGravity(false);
    player.setXVelocity(Math.round(Math.calculateXVelocity(movingSpeed, angle)));
    player.setYVelocity(Math.round(-Math.calculateYVelocity(movingSpeed, angle)));

    var period = (movingSpeed == 1) ? 45 : 18;
    player.addTimer(period, 1, function () {
        player.toggleGravity(true);
        player.resetMomentum();
        var jumps = [];
        Engine.forEach(player.getCharacterStat("doubleJumpSpeeds"), function (num: Float, idx: Int) {
            jumps.push(num);
            return true;
        }, []);

        var leftDodge = false;
        function afterDodge() {
            if (!leftDodge) {
                player.removeEventListener(GameObjectEvent.LAND, afterDodge);
                player.removeEventListener(GameObjectEvent.ENTER_HITSTUN, afterDodge);
                leftDodge = true;
                switch (variant) {
                    case ULTIMATE_VARIANT:
                        enableActions(player)(null);
                }
                if (jumps.length > 0) {
                    player.updateCharacterStats({ doubleJumpSpeeds: jumps });
                }

            }
        }
        if (variant == ULTIMATE_VARIANT) {
            var gravity = player.getGameObjectStat("gravity");
            var distance = 215 + (Math.calculateYVelocity(movingSpeed, angle) * period);
            var dodgeTime = Math.sqrt(((2 * distance) / gravity));
            player.updateCharacterStats({ doubleJumpSpeeds: [] });
            disableAllAttacks(player);
            player.addTimer(dodgeTime, 1, afterDodge, { persistent: true });
        }
        player.addEventListener(GameObjectEvent.LAND, afterDodge, { persistent: true });
        player.addEventListener(GameObjectEvent.HIT_RECEIVED, afterDodge, { persistent: true });
        player.endAnimation();
    });

    return vector;

}


function mvsMode(player: Character) {
    player.updateCharacterStats({ airdashLimit: 2 });

    player.addEventListener(EntityEvent.COLLIDE_STRUCTURE, function () {
        superPreland(player);
    }, { persistent: true });
    player.addEventListener(EntityEvent.STATE_CHANGE, function (e: EntityEvent) {
        var toState = e.data.toState;
        if (player.inAerialAttackState()) {
            player.setYVelocity((player.getYVelocity() * 0.1));
            player.updateAnimationStats({ gravityMultiplier: 0.2, ySpeedConservation: 0.2, xSpeedConservation: 0.2, terminalVelocity: 1, landType: LandType.NONE, xSpeedConservation: 0, allowMovement: false });
        }

        switch (toState) {
            case CState.GRAB:
                directionToStrong(player);
            case CState.PARRY_IN:
                directionToStrong(player);
            case CState.SHIELD_IN:
                directionToNormal(player);
            case CState.AIRDASH_INITIAL:
                performAirdodge(player, GENERIC_VARIANT);


        }

    }, { persistent: true });
}
var TILT = 0;
var AERIAL = 1;
var STRONG = 2;
var SPECIAL = 3;
var ups = [CState.TILT_UP, CState.AERIAL_UP, CState.STRONG_UP_ATTACK, CState.SPECIAL_UP];

var downs = [CState.TILT_DOWN, CState.AERIAL_DOWN, CState.STRONG_DOWN_ATTACK, CState.SPECIAL_DOWN];

var backwards = [CState.TILT_FORWARD, CState.AERIAL_BACK, CState.STRONG_FORWARD_ATTACK, CState.SPECIAL_SIDE];

var forwards = [CState.TILT_FORWARD, CState.AERIAL_FORWARD, CState.STRONG_FORWARD_ATTACK, CState.SPECIAL_SIDE];

var neutrals = [CState.JAB, CState.AERIAL_NEUTRAL, CState.STRONG_FORWARD_ATTACK, CState.SPECIAL_NEUTRAL];


function directionToNormal(player: Character) {
    if (player.isOnFloor()) {
        directionToAttack(player, TILT);
    } else {
        directionToAttack(player, AERIAL);

    }
}

function directionToStrong(player: Character) {
    if (player.isOnFloor()) {
        directionToAttack(player, STRONG);
    } else {
        directionToAttack(player, AERIAL);
    }
}

function directionToSpecial(player: Character) {
    directionToAttack(player, SPECIAL);
}

function directionToAttack(player: Character, variant: Int) {
    var held = player.getHeldControls();
    var pressed = player.getPressedControls();
    var left = held.LEFT || pressed.LEFT;
    var right = held.RIGHT || pressed.RIGHT;
    var up = held.UP || pressed.UP;
    var down = held.DOWN || pressed.DOWN;
    var neutral = !(up || down || left || right);
    var rightStickRelevant = (held.hasRightStickAttackFlag() && variant != SPECIAL) || (held.hasRightStickSpecialFlag && variant == SPECIAL);
    if (rightStickRelevant) {
        left = left || held.RIGHT_STICK_LEFT;
        right = right || held.RIGHT_STICK_RIGHT;
        up = up || held.RIGHT_STICK_UP;
        down = down || held.RIGHT_STICK_DOWN;
    }

    if (up) {
        var toState = ups[variant];
        player.toState(toState);
    } else if (down) {
        var toState = downs[variant];
        player.toState(toState);
    } else if (right) {
        var toState = -1;

        if (!player.isFacingRight() && (variant != AERIAL)) {
            player.flip();
        }

        if (player.isFacingRight()) {
            toState = forwards[variant];
        } else {
            toState = backwards[variant];
        }
        player.toState(toState);

    } else if (left) {
        var toState = -1;

        if (!player.isFacingLeft() && (variant != AERIAL)) {
            player.flip();
        }

        if (player.isFacingLeft()) {
            toState = forwards[variant];
        } else {
            toState = backwards[variant];
        }

        player.toState(toState);
    } else if (neutral) {
        var toState = neutrals[variant];
        player.toState(toState);
    }
}

function disableAllAttacks(player: Character) {
    Engine.forEach(allActions, function (action: Int, _idx: Int) {
        player.addStatusEffect(StatusEffectType.DISABLE_ACTION, action, { tag: STATUS_TAG });
        return true;
    }, []);
}
function enableAirActions(player: Character) {
    return function (event: GameObjectEvent) {
        var disabledStatus = player.findStatusEffectObjectsByTag(StatusEffectType.DISABLE_ACTION, STATUS_TAG);
        Engine.forEach(disabledStatus, function (effect: any, _idx: Int) {
            player.removeStatusEffect(StatusEffectType.DISABLE_ACTION, effect.id);
        }, []);
    }
}


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

    var closestXBoundDistance = (components.x < 0) ? leftDistance : rightDistance;
    var closestYBoundDistance = (components.y < 0) ? upDistance : downDistance;
    return { x: closestXBoundDistance, y: closestYBoundDistance };

}

function finishZoom(event: GameObjectEvent) {
    var victim: Character = event.data.self;
    var stats = event.data.hitboxStats;
    if (finishZoomCheck(victim, stats)) {
        applyKillSpark(0, victim, Math.getAngleFromVelocity(victim.getXKnockback(), victim.getYKnockback()), 1.5, victim);
        event.data.hitboxStats.hitstop = stats.hitstop + 10;
        event.data.hitboxStats.selfHitstop = stats.selfHitstop + 10;
        var duration = stats.selfHitstop + 10;

        // Training Mode or Last Stock
        if (match.getMatchSettingsConfig().matchRules[0].contentId == "infinitelives" || gameEndingStock(victim)) {
            zoomInOnPlayer(event.data.self, duration + 35);
            if (event.data.foe != null) {
                event.data.foe.forceStartHitstop(stats.hitstop + 35, true);
            }
            event.data.self.forceStartHitstop(stats.selfHitstop + 35, true);
            darkenScreen(duration + 35, 12);
            slowMotion(duration + 35, true);
            AudioClip.play(getContent("finishZoom"), { loop: false, volume: 0.38 });

        } else { // Regular Kills
            if (event.data.foe != null) {
                event.data.foe.forceStartHitstop(stats.hitstop + 20, true);
            }
            event.data.self.forceStartHitstop(stats.selfHitstop + 20, true);
            darkenScreen(duration + 20, 12);
            slowMotion(duration + 20, true);
            AudioClip.play(getContent("finishZoom"), { loop: false, volume: 0.3 });

        }
    }

}

function finishZoomCheck(victim: GameObject, stats: HitboxStats): Bool {
    if (victim.hasBodyStatus(BodyStatus.INVINCIBLE) || !stats.flinch) {
        return false;
    }

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
    var autoLinkAngles = [SpecialAngle.AUTOLINK_STRONGER, SpecialAngle.AUTOLINK_STRONGEST, SpecialAngle.AUTOLINK_WEAK];
    if (autoLinkAngles.indexOf(stats.rawAngle) < 0 && (distanceComponents.x >= (boundDistance.x * 1.1) || distanceComponents.y > (boundDistance.y * 1.1))) {
        return true;
    }
    return false;
}

function gameEndingStock(player: Character) {
    if (match.getMatchSettingsConfig().lives < 0) {
        return false;
    }
    var lives = player.getLives();
    if (lives > 1) {
        return false;
    }
    var foes = player.getFoes();
    var allies = match.getPlayers().length - foes.length;
    if (allies == 1) {
        return true;
    }
}

function enableActions(player: Character) {
    return function (event: GameObjectEvent) {
        var disabledStatus = player.findStatusEffectObjectsByTag(StatusEffectType.DISABLE_ACTION, STATUS_TAG);
        Engine.forEach(disabledStatus, function (effect: any, _idx: Int) {
            player.removeStatusEffect(StatusEffectType.DISABLE_ACTION, effect.id);
            return true;
        }, []);
    }
}


function disableActions(player: Character) {
    Engine.forEach(allActions, function (action: Int, _idx: Int) {
        player.addStatusEffect(StatusEffectType.DISABLE_ACTION, action, { tag: STATUS_TAG });
        return true;
    }, []);
}


function createAfterImage(obj: GameObject, duration: Int, filter: Filter) {
    var vfx: Vfx = match.createVfx(new VfxStats({
        spriteContent: obj.getGameObjectStat("spriteContent"),
        animation: obj.getAnimation(),
        fadeOut: true,
        resizeWith: true,
        loop: false,
        timeout: duration,
        layer: VfxLayer.CHARACTERS_BACK
    }), obj);
    vfx.setX(obj.getX());
    vfx.setY(obj.getY());
    vfx.playFrame(obj.getCurrentFrame());
    if (filter != null) {
        vfx.addFilter(filter);
    }
    var cSh = obj.getCostumeShader();
    if (cSh != null) {
        vfx.addShader(cSh);
    }
    return vfx;
}



function defaultFinalSmash(player: Character) {
    var duration = 3.5 * 60;
    var port = player.getPlayerConfig().port;
    if (!player.isOnFloor()) {
        player.playAnimation("assist_call_air");
    } else {
        player.playAnimation("assist_call");
    }

    var filter = new HsbcColorFilter();
    filter.hue = -Math.toRadians(180);
    filter.saturation = 1;
    var objs = filterEverything(filter);
    player.removeFilter(filter);
    player.getDamageCounterContainer().removeFilter(filter);

    var allowList = [player, self];
    var aaTime = player.addTimer(3, -1, function () {
        for (item in allowList) {
            if (item.isDisposed()) { allowList.remove(item); }
        }
        match.freezeScreen(1, allowList);
        var aa = createAfterImage(player, 10, null);
        aa.setAlpha(0.4);
    }, { persistent: true });
    function projectileCreated(e: GameObjectEvent) {
        allowList.push(e.data.other);
    }
    player.addEventListener(GameObjectEvent.PROJECTILE_CREATED, projectileCreated, { persistent: true });

    var port = player.getPlayerConfig().port;
    globalController.exports.data.finalSmashForm[port] = true;
    var outerGlow = new GlowFilter();
    outerGlow.color = 0x0e0e0e;
    var innerGlow = new GlowFilter();
    innerGlow.color = 0xFFFFFF;

    player.addFilter(innerGlow);
    player.addFilter(outerGlow);

    var curr = 0;
    var mult = 1;
    var uid = player.addTimer(1, duration, function () {
        globalController.exports.data.meters[port].sprite.currentFrame = 0;
        if (!player.inState(CState.HELD)) { player.updateAnimationStats({ bodyStatusStrength: 10 }); }
        if (curr % 20 == 0) { mult = mult * -1; }
        outerGlow.alpha -= 0.05 * (mult);
        innerGlow.alpha += 0.05 * (mult);
        curr++;
    }, { persistent: true });


    var removeBuff = function () {
        globalController.exports.data.finalSmashForm[port] = false;
        player.removeTimer(aaTime);
        player.removeTimer(uid);
        player.removeFilter(outerGlow);
        player.removeFilter(innerGlow);
        removeFilters(objs, filter);
    }
    player.addEventListener(GameObjectEvent.HIT_RECEIVED, removeBuff, { persistent: true });
    player.addEventListener(CharacterEvent.KNOCK_OUT, removeBuff, { persistent: true });
    player.addTimer(duration, 1, removeBuff, { persistent: true });
}


function performFinalSmash(player: Character) {
    var port = player.getPlayerConfig().port;
    globalController.exports.data.meters[port].sprite.currentFrame = 0;
    if (player.hasAnimation("final_smash")) {
        player.endAnimation();
        player.playAnimation("final_smash");
        player.playFrame(1);
        player.addTimer(1, player.getTotalFrames() + 500, function () {
            globalController.exports.data.meters[port].sprite.currentFrame = 0;
        }, { persistent: true });
    } else {
        player.endAnimation();
        player.playAnimation("assist_call");
        defaultFinalSmash(player);
    }
}





function filterEverything(filter: Filter) {
    var containers = camera.getBackgroundContainers(); // might as well set it to this in adcance
    containers = containers.concat([
        // Camera Stuff
        camera.getBackgroundContainer(),
        camera.getForegroundContainer(),

        // Effects
        stage.getBackgroundBehindContainer(),
        stage.getBackgroundEffectsContainer(),
        stage.getBackgroundShadowsContainer(),
        stage.getBackgroundStructuresContainer(),
        stage.getCharactersFrontContainer(),
        stage.getForegroundEffectsContainer(),
        stage.getForegroundFrontContainer(),
        stage.getForegroundShadowsContainer(),
        stage.getForegroundStructuresContainer(),
    ]);

    // Extra Stuff Containers may have missed
    Engine.forEach(match.getCollisionAreas(), function (col: CollisionArea, _idx: Int) {
        var c = col;
        containers.push(c);
        return true;
    }, []);

    Engine.forEach(match.getCustomGameObjects(), function (obj: CustomGameObject, _idx: Int) {
        var c = obj;
        containers.push(c);
        return true;
    }, []);

    Engine.forEach(match.getStructures(), function (structure: Structure, _idx: Int) {
        var c: Structure = structure;
        containers.push(c);
        return true;
    }, []);

    Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
        containers.push(player.getDamageCounterContainer());
        containers.push(player);
        return true;
    }, []);

    var containerObjs: Array<{ item: DisplayObject, filter: HsbcColorFilter }> = [];

    Engine.forEach(containers, function (container: DisplayObject, _idx: Int) {
        if (container != null) {
            container.addFilter(filter);
            containerObjs.push({ item: container, filter: filter });
        }
        return true;
    }, []);
    return containerObjs;
}

function removeFilters(objs: Array<{ item: DisplayObject, filter: HsbcColorFilter }>) {
    Engine.forEach(objs, function (obj: { item: DisplayObject, filter: HsbcColorFilter }) {
        obj.item.removeFilter(obj.filter);
        return true;
    }, []);
}

function filterEverythingTimer(duration: Int, filter: Filter) {
    var objs = filterEverything(filter);
    var undo = function () {
        removeFilters(objs);
    };
    self.addTimer(duration, 1, undo, { duration: true });
}

function clearSprites(textSprites: Array<Sprite>) {
    Engine.forEach(textSprites, function (sprite: Sprite, idx: Int) {
        sprite.dispose();
        return true;
    }, []);
    textSprites = [];

}

function enterDizzy(player: Character, callback) {
    player.takeHit(new HitboxStats({ damage: 0, baseKnockback: 80, hitstun: 60 * 1, angle: 90, reflectable: false, absorbable: false, shieldable: false, directionalInfluence: false, tumbleType: TumbleType.ALWAYS }));

    var breakStatus = player.applyGlobalBodyStatus(BodyStatus.INVINCIBLE, 60);
    player.updateAnimationStats({ landType: LandType.NONE });
    var stunVfx = null;

    function leaveShieldStun() {
        if (stunVfx != null) {
            stunVfx.kill();
            stunVfx = null;
            leftShieldStun = true;
            callback();
        }
    };


    player.addEventListener(EntityEvent.COLLIDE_FLOOR, function onCollideFloor(event: EntityEvent) {
        player.removeEventListener(EntityEvent.COLLIDE_FLOOR, onCollideFloor);

        breakStatus.finish();
        stunVfx = match.createVfx(new VfxStats({
            spriteContent: getContent("roundShield"), resizeWith: true, animation: "stunVfx", loop: true, y: -player.getEcbCollisionBox().height
        }, player));

        stunVfx.attachTo(player);
        player.setState(CState.EMOTE);
        player.playAnimation("stand");

        var grabFn = null;
        var hitFn = null;
        function onHit(event: GameObjectEvent) {
            hitFn = onHit;
            if (event.data.hitboxStats.flinch) {
                player.removeEventListener(GameObjectEvent.HIT_RECEIVED, grabFn);
                player.removeEventListener(EntityEvent.STATE_CHANGE, hitFn);

                leaveShieldStun();
            }
        }

        function onGrabbed(event: EntityEvent) {
            grabFn = onGrabbed;
            if (event.data.toState == CState.HELD) {
                player.removeEventListener(GameObjectEvent.HIT_RECEIVED, hitFn);
                player.removeEventListener(EntityEvent.STATE_CHANGE, grabFn);

                leaveShieldStun();
            }
        }

        player.addEventListener(GameObjectEvent.HIT_RECEIVED, onHit, { persistent: true });
        player.addEventListener(EntityEvent.STATE_CHANGE, onGrabbed, { persistent: true });
    }, { persistent: false });

    player.addTimer(60 * 5, 1, function () {

        leaveShieldStun();
        if (player.isOnFloor()) { player.toState(CState.STAND); } else { player.toState(CState.FALL); }
    }, { persistent: true });
}

function getScales(player: Character) {
    var widthScale = player.getScaleX();
    var heightScale = player.getScaleY();
    var effectScale = 1;
    var resizeStatuses = player.getStatusEffectByType(StatusEffectType.SIZE_MULTIPLIER);
    if (resizeStatuses != null) {
        effectScale = resizeStatuses.getProduct();
    }
    var heightStatuses = player.getStatusEffectByType(StatusEffectType.HEIGHT_MULTIPLIER);
    if (heightStatuses != null) {
        heightScale = heightScale * heightStatuses.getProduct();
    }

    var widthStatuses = player.getStatusEffectByType(StatusEffectType.WIDTH_MULTIPLIER);
    if (widthStatuses != null) {
        widthScale = widthScale * widthStatuses.getProduct();
    }
    var res = {
        width: widthScale * effectScale,
        height: heightScale * effectScale,
        base: effectScale
    };
    return res;
}

function onParriedReceiverEnd(defender: Character, attacker: GameObject, stats: HitboxStats) {
    if (defender.getType() == EntityType.CHARACTER && defender.inState(CState.SHIELD_OUT) && defender.getCurrentFrame() < PARRY_WINDOW) {
        darkenScreen(15, 10);
        defender.setDamage(defender.getDamage() - stats.damage);
        defender.setKnockback(0, 0);
        defender.setYVelocity(0);
        defender.setXVelocity(0);
        defender.resetMomentum();
        defender.toState(CState.PARRY_SUCCESS);
        defender.updateAnimationStats({ bodyStatus: BodyStatus.INVINCIBLE });
        defender.addTimer(5, 1, function () {
            if (defender.inState(CState.PARRY_SUCCESS) && defender.hasBodyStatus(BodyStatus.INVINCIBLE)) {
                defender.updateAnimationStats({ bodyStatus: BodyStatus.NONE });
            }
        }, { persistent: true });
        AudioClip.play(getContent("UltimateParry"), { volume: 0.8, });
        defender.addTimer(30, 1, function () {
            sound = null;
        }, { persistent: true });

        defender.forceStartHitstop(defender.getHitstop() + 11);
        defender.addTimer(11, 1, function () {
            defender.endAnimation();
        });
        attacker.forceStartHitstop(attacker.getHitstop() + 14);
    }
}

function onParriedProjectile(event: GameObjectEvent) {
    var attacker: Character = event.data.foe;
    var defender: GameObject = event.data.self;
    onParriedReceiverEnd(defender, attacker, event.data.hitboxStats);
}

function playerParryListener(event: GameObjectEvent) {
    var defender: GameObject = event.data.foe;
    var attacker: GameObject = event.data.self;
    onParriedReceiverEnd(defender, attacker, event.data.hitboxStats);
}

function createShield(player: Character, variant: Int) {
    var spriteContent = player.getGameObjectStat("spriteContent");

    if (noShielders.contains(spriteContent)) {
        return {
            dispose: function () { }
        };
    }
    if (stage.exports.frayifitwasgood != null) {
        return;
    }
    player.updateCharacterStats({
        shieldBackXOffset: 10000000,
        shieldBackYOffset: 10000000,
        shieldFrontXOffset: 10000000,
        shieldFrontYOffset: 10000000,
        shieldCrossupThreshold: Math.POSITIVE_INFINITY
    });

    var events: Array<Array<Any>> = [];
    var timers: Array<Int> = [];
    var smash64Preset = {
        hp: 55,
        damageFormula: function (damage: Float) { return damage; },
        depleteRate: 0.0625,
        regenRate: 0.1,
        resetValue: 30,
        timeTodrop: 3
    };
    var ultimatePreset = {

        hp: 50,
        damageFormula: function (damage: Float) {
            var shieldDamage = Math.ceil(damage * 0.5);
            return shieldDamage;
        },
        depleteRate: 0.15,
        regenRate: 0.08,
        resetValue: 37.5,
        timeTodrop: 3
    };

    var meleePreset = {
        hp: 60,
        damageFormula: function (damage: Float) {
            var shieldDamage = Math.ceil(damage * 0.7);
            return shieldDamage;
        },
        depleteRate: 0.0625,
        regenRate: 0.1,
        resetValue: 30,
        timeTodrop: 8
    };


    var settings: {
        hp: number,
        damageFormula: Function,
        depleteRate: number,
        regenRate: number,
        resetValue: number,
        timeTodrop: number
    } = {};
    switch (variant) {
        case SMASH64_VARIANT:
            settings = smash64Preset;
        case ULTIMATE_VARIANT:
            settings = ultimatePreset;
        default:
            settings = meleePreset;
    }

    var shader: RgbaColorShader = createColorShader(player.getPortColor());
    var dropTime = settings.timeTodrop;
    var shield = match.createVfx(new VfxStats({
        spriteContent: getContent("roundShield"),
        animation: "shield",
        x: 0,
        y: 0,
        resizeWith: true,
        loop: true
    }), null);

    shield.addShader(shader);
    shield.setAlpha(0);

    var shieldHeight = shield.getSprite().height;
    var yOffset = 0;
    var xOffset = 0;
    var currentHP = settings.hp;


    function updateScale() {
        var scale = getScales(player);
        var widthScale = scale.width;
        var heightScale = scale.height;
        var effectScale = scale.base;
        var characterHeight = player.getSprite().height * heightScale;
        var characterWidth = player.getSprite().width * widthScale;
        var characterSize = characterHeight > characterWidth ? characterHeight : characterWidth;
        var scale = effectScale * (characterSize * 1.3) / shieldHeight;
        shield.setScaleX((currentHP / settings.hp) * scale);
        shield.setScaleY((currentHP / settings.hp) * scale);
        yOffset = characterHeight / -2;
    }
    updateScale();

    function grow(amount) {
        if (currentHP + amount < settings.hp) { currentHP += amount; } else { currentHP = settings.hp; }
        updateScale();
    }

    function shrink(amount: Float) {
        if (currentHP - amount > 0) { currentHP -= amount; } else { currentHP = 0; }
        updateScale();
    }

    function hide() { shield.setAlpha(0); }
    function show() { shield.setAlpha(1); }
    function visible() { return shield.getAlpha() > 0; }
    function getLevel() { return currentHP; }

    function getTimeToDrop() { return dropTime; }
    function reset() { currentHP = settings.resetValue; }


    var updateTimer = shield.addTimer(1, -1, function () {
        shield.setX(xOffset + player.getX());
        shield.setY(yOffset + player.getY());

        if (player.inState(CState.SHIELD_IN) || player.inState(CState.SHIELD_LOOP) || player.inState(CState.SHIELD_HURT)) {
            show();
        } else {
            hide();
        }
        if (!player.inState(CState.SHIELD_HURT)) {
            if (!visible()) {
                grow(settings.regenRate);
            } else {
                shrink(settings.depleteRate);
            }
        }
        var held = player.getHeldControls();
        var pressing = player.getHeldControls();
        var notPressingShield = !(
            held.SHIELD || held.SHIELD1 || held.SHIELD2 || held.SHIELD_AIR
            || pressing.SHIELD || pressing.SHIELD1 || pressing.SHIELD2 || pressing.SHIELD_AIR
        );

        if (player.inState(CState.SHIELD_LOOP) || player.inState(CState.SHIELD_IN) || notPressingShield) {
            if (dropTime > 0) {
                dropTime--;
            }
        } else {
            dropTime = settings.timeTodrop;
        }

        if (getLevel() == 0) {
            enterDizzy(player, reset);
        }
    }, { persistent: true });

    timers.push(updateTimer);

    var parryStatus: BodyStatusTimer = null;


    function onStateChange(event: EntityEvent) {
        var toState = event.data.toState;
        var fromState = event.data.fromState;
        var fromShield = (fromState == CState.SHIELD_OUT
            || fromState == CState.SHIELD_IN
            || fromState == CState.SHIELD_LOOP
            || fromState == CState.SHIELD_HURT
            || fromState == CState.SHIELD_BREAK);

        if (!fromShield && toState == CState.SHIELD_IN) {
            shieldStarted = true;
        } else if (fromState != toState
            && (fromState == CState.SHIELD_IN || fromState == CState.SHIELD_LOOP || fromState == CState.SHIELD_HURT)
            && toState == CState.SHIELD_OUT && dropTime > 0) {
            player.setState(CState.SHIELD_LOOP);
            forceShield = true;
        }

        if (variant == ULTIMATE_VARIANT) {
            if (fromState == CState.SHIELD_OUT && parryStatus != null) { parryStatus.finish(); }

            if (getTimeToDrop() == 0 && toState == CState.SHIELD_OUT) {
                if (parryStatus == null) {
                    parryStatus = player.applyGlobalBodyStatus(BodyStatus.INVINCIBLE_GRABBABLE, PARRY_WINDOW);
                } else {
                    parryStatus.reset();
                }
            }

        }

    }

    function onShieldHit(event: GameObjectEvent) {
        var stats = event.data.hitboxStats;
        if (stats.flinch && stats.damage > 0) {
            shrink(settings.damageFormula(stats.damage) * stats.shieldDamageMultiplier);
        }
        if (event.data.foe.getX() > player.getX() && player.isFacingLeft()) {
            player.setXKnockback(-player.getXKnockback());
        }
        else if (event.data.foe.getX() < player.getX() && player.isFacingRight()) {
            player.setXKnockback(-player.getXKnockback());
        }
    }


    events.push([EntityEvent.STATE_CHANGE, onStateChange]);
    events.push([GameObjectEvent.SHIELD_HIT_RECEIVED, onShieldHit]);

    player.addEventListener(EntityEvent.STATE_CHANGE, onStateChange, { persistent: true });
    player.addEventListener(GameObjectEvent.SHIELD_HIT_RECEIVED, onShieldHit, { persistent: true });

    if (variant == ULTIMATE_VARIANT) {
        events.push([GameObjectEvent.HIT_RECEIVED, onParriedProjectile]);
        events.push([GameObjectEvent.HITBOX_CONNECTED, playerParryListener]);
        player.addEventListener(GameObjectEvent.HIT_RECEIVED, onParriedProjectile, { persistent: true });
        player.addEventListener(GameObjectEvent.HITBOX_CONNECTED, playerParryListener, { persistent: true });
    }

    return {
        dispose: function () { genericDispose(player, timers, events); }
    }
}


function getAirDodgeAngle(player: Character, speed: Int) {
    var held = player.getHeldControls();
    var pressed = player.getPressedControls();
    var left = held.LEFT || pressed.LEFT;
    var right = held.RIGHT || pressed.RIGHT;
    var up = held.UP || pressed.UP;
    var down = held.DOWN || pressed.DOWN;
    var cAirDash = !(held.hasRightStickAttackFlag() || held.hasRightStickAttackFlag());
    if (cAirDash) {
        left = left || held.RIGHT_STICK_LEFT || pressed.RIGHT_STICK_LEFT;
        right = right || held.RIGHT_STICK_RIGHT || pressed.RIGHT_STICK_RIGHT;
        up = up || held.RIGHT_STICK_UP || pressed.RIGHT_STICK_UP;
        down = down || held.RIGHT_STICK_DOWN || pressed.RIGHT_STICK_DOWN;
    }
    var movingSpeed = speed;
    var angle = 0;

    if (left && up) {
        angle = 135;
    } else if (left && down) {
        angle = 225;
    } else if (left) {
        angle = 180;
    } else if (right && up) {
        angle = 45;
    } else if (right && down) {
        angle = 315;
    } else if (right) {
        angle = 0;
    } else if (up) {
        angle = 90;
    } else if (down) {
        angle = 270;
    } else {
        angle = 90;
        movingSpeed = 0;
    }
    // var ret = { angle: angle, movingSpeed: movingSpeed };
    return { angle: angle, movingSpeed: movingSpeed };

}




function ultimateModeOnStateChange(player: Character) {
    return function (e: EntityEvent) {
        var toState = e.data.toState;
        var fromState = e.data.fromState;
        switch (toState) {
            case CState.AIRDASH_INITIAL:
                if (stage.exports.frayifitwasgood == null || noShielders.contains(player.getGameObjectStat("spriteContent"))) {
                    performAirdodge(player, ULTIMATE_VARIANT);
                }
            case CState.PARRY_IN:
                player.toState(CState.SHIELD_HURT, "shield_loop");
        }

    }
}



function ultimateMode(player: Character): void {
    var finalSmash = activateFinalSmashMeter(player);
    var timers = [];
    var events = [];
    function hitConnected(event: GameObjectEvent) {
        event.data.hitboxStats.shieldstunMultiplier = 3;
    }
    // Setup Shi
    // player.updateCharacterStats({ airdashInitialSpeed: 3, airdashSpeedCap: 6, airdashStartupLength: 1, airdashFullspeedLength: 30 });
    player.updateCharacterStats({ airdashTrailEffect: getContent("controller") });

    var enableAir = enableActions(player);
    var shield = createShield(player, ULTIMATE_VARIANT);
    var stateChange = ultimateModeOnStateChange(player);
    player.addEventListener(GameObjectEvent.LAND, enableAir, { persistent: true });
    player.addEventListener(EntityEvent.STATE_CHANGE, stateChange, { persistent: true });
    player.addEventListener(GameObjectEvent.HIT_RECEIVED, finishZoom, { persistent: true });
    player.addEventListener(GameObjectEvent.HITBOX_CONNECTED, hitConnected, { persistent: true });

    events.push([GameObjectEvent.HIT_RECEIVED, finishZoom]);
    events.push([EntityEvent.STATE_CHANGE, stateChange]);
    events.push([GameObjectEvent.LAND, enableAir]);
    events.push([GameObjectEvent.HITBOX_CONNECTED, hitConnected]);





    timers.push(player.addTimer(1, -1, function () {
        if (globalController.exports.data.meters == null) {
            return;
        }
        var port = player.getPlayerConfig().port;
        var charge = globalController.exports.data.meters[port].sprite.currentFrame;
        if (player.getAnimation() != "final_smash"
            && hasMatchOrSubstring(actionable_animations, player.getAnimation())
            && player.getHeldControls().EMOTE
            && charge >= FINAL_SMASH_CHARGE
        ) {
            globalController.exports.data.meters[port].sprite.currentFrame = 0;
            performFinalSmash(player);
        }
    }, { persistent: true }));

    return {
        dispose: function () {
            genericDispose(player, timers, events);
            finalSmash.dispose();
        }
    }


}

function createFinalSmashMeter(player: Character) {
    var damageContainer = player.getDamageCounterContainer();
    var res = getContent("fsMeter");
    var sprite = Sprite.create(res);
    sprite.scaleX = 0.3;
    sprite.scaleY = 0.5;
    sprite.x = 64 + 32 + 8 + 12 + 9;
    sprite.y = 14 + 16 + 2;
    sprite.currentFrame = 0;
    damageContainer.addChild(sprite);
    var filter = new HsbcColorFilter();
    filter.saturation = 1.0;
    filter.hue = Random.getFloat(0, 1);
    sprite.addFilter(filter);
    return {
        sprite: sprite,
        filter: filter
    }
}


function activateFinalSmashMeter(player: Character) {
    var timers = [];
    var events = [];
    if (globalController.exports.data.finalSmashForm == null) {
        globalController.exports.data.finalSmashForm = [false, false, false, false];
    }
    if (globalController.exports.data.meters == null) {
        globalController.exports.data.meters = [null, null, null, null];

    }
    var port = player.getPlayerConfig().port;
    globalController.exports.data.meters[port] = createFinalSmashMeter(player);
    var spriteObj = globalController.exports.data.meters[port];
    var meter: Sprite = spriteObj.sprite;
    var filter: HsbcColorFilter = spriteObj.filter;

    timers.push(player.addTimer(1, -1, function () {
        if (meter.currentFrame >= FINAL_SMASH_CHARGE) {
            filter.hue += 0.05;
        } else {
            filter.hue += 0.01;
        }
        if ((match.getMatchSettingsConfig().matchRules[0].contentId == "infinitelives") && player.getHeldControls().EMOTE && player.getHeldControls().DOWN) {
            if (meter.currentFrame + 1 < FINAL_SMASH_CHARGE) {
                meter.currentFrame += 10;
            } else {
                meter.currentFrame = FINAL_SMASH_CHARGE;
            }
        } else if (player.getAnimation() == "final_smash" && player.getCurrentFrame() == player.getTotalFrames()) {
            player.addTimer(1, 300, function () {
                meter.currentFrame = 0;
            }, { persistent: true });
        }
    }, { persistent: true }));
    function hitReceived(event: GameObjectEvent) {
        var charge = meter.currentFrame;
        if (player.getAnimation() != "final_smash" && !event.data.self.hasBodyStatus(BodyStatus.INVINCIBLE)) {
            var damage = Math.round(event.data.hitboxStats.damage * 2.5);
            if (charge + damage >= FINAL_SMASH_CHARGE) {
                meter.currentFrame = FINAL_SMASH_CHARGE;
            } else {
                meter.currentFrame += damage;
            }
        }

    }
    function hitDealt(event: GameObjectEvent) {
        var charge = meter.currentFrame;
        if (player.getAnimation() != "final_smash" && !event.data.foe.hasBodyStatus(BodyStatus.INVINCIBLE)) {
            var damage = Math.ceil(event.data.hitboxStats.damage);
            if (charge + damage >= FINAL_SMASH_CHARGE) {
                meter.currentFrame = FINAL_SMASH_CHARGE;
            } else {
                meter.currentFrame += damage;
            }
        }

    }
    player.addEventListener(GameObjectEvent.HIT_RECEIVED, hitReceived, { persistent: true });
    player.addEventListener(GameObjectEvent.HIT_DEALT, hitDealt, { persistent: true });
    events.push([GameObjectEvent.HIT_DEALT, hitDealt]);
    events.push([GameObjectEvent.HIT_RECEIVED, hitReceived]);
    return {
        dispose: function () {
            genericDispose(player, timers, events);
            meter.dispose();
        }
    }
}

function enableUltimateMode() {
    Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
        ultimateMode(player);
        return true;
    }, []);
}
function smash64Mode(player: Character) {
    player.addStatusEffect(StatusEffectType.ATTACK_HITSTUN_MULTIPLIER, 1.5);
    player.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.THROW_DOWN);
    player.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.THROW_UP);
    player.updateCharacterStats({ airdashLimit: 0 });

    var shield = createShield(player, SMASH64_VARIANT);

    player.addEventListener(EntityEvent.STATE_CHANGE, function (e: EntityEvent) {
        var toState = e.data.toState;
        if (toState == CState.SPECIAL_SIDE) {
            player.toState(CState.SPECIAL_NEUTRAL);
        }
    }, { persistent: true });

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
        event.data.hitboxStats.hitstopNudgeMultiplier = 2;
        event.data.hitboxStats.shieldstunMultiplier = 5;
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
    globalController.exports.data.coins[port] = Math.min(9999, Math.max(0, Math.floor(coins)));
    var coinSprites = globalController.exports.data.coinSprites[port];
    refreshCoins(coinSprites, getCoins(player));

}
function addCoins(player: Character, coins: Int) {
    setCoins(player, getCoins(player) + coins);
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
    addCoins(player, -damage);
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
                addCoins(foe, Math.min(damage, 9999));
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
        if (GraphicsSettings.damageHudPosition == "top") {
            sprite.y = sprite.y + 64;
        } else {
            sprite.y = sprite.y - 16;
        }
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
    globalController.exports.data.coins = [0, 0, 0, 0];

    globalController.exports.data.coinSprites = [[], [], [], []];

    globalController.exports.data.spawnPositions = [{}, {}, {}, {}];


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
                            foe.toState(CState.KO);
                        }, { persistent: true });
                        return true;
                    }, []);


                } else {
                    Engine.forEach(players, function (player: Character, _idx: Int) {
                        player.setLives(1);
                        player.addTimer(1, 20, function () {
                            if (winners.indexOf(player) < 0) {
                                player.toState(CState.KO);
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

function disposeSprites(textSprites: Array<Sprite>) {
    Engine.forEach(textSprites, function (sprite: Sprite, idx: Int) {
        sprite.dispose();
        return true;
    }, []);
    textSprites = [];
}


function createSpriteFromCharacter(char: String): Sprite {
    var res = getContent("text");
    var lowerCase = "abcdefghijklmnopqrstuvwxyz";
    var upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    var digits = "0123456789";
    var symbols = "!\"#$%&'()*+,-./;<=>?@:[\\]^_`{|}~ ";

    var lowerCaseIndex = lowerCase.indexOf(char);
    var upperCaseIndex = upperCase.indexOf(char);
    var digitIndex = digits.indexOf(char);
    var symbolIndex = symbols.indexOf(char);

    var isDigit = digitIndex >= 0;
    var isLowerCase = lowerCaseIndex >= 0;
    var isUpperCase = upperCaseIndex >= 0;
    var isSymbol = symbolIndex >= 0;

    var sprite: Sprite = Sprite.create(res);
    if (isDigit) {
        sprite.currentAnimation = "digits";
        sprite.currentFrame = digitIndex + 1;
    } else if (isSymbol) {
        sprite.currentAnimation = "symbols";
        sprite.currentFrame = symbolIndex + 1;
    } else if (isLowerCase) {
        sprite.currentAnimation = "lowercase";
        sprite.currentFrame = lowerCaseIndex + 1;
    } else if (isUpperCase) {
        sprite.currentAnimation = "uppercase";
        sprite.currentFrame = upperCaseIndex + 1;
    } else {
        sprite.currentAnimation = "symbols";
        sprite.currentFrame = symbols.length - 1;
    }

    return sprite;
}


function parseHexCode(hex: String): Int {
    var total: Int = 0;
    hex = hex.toUpperCase();
    var digits = "0123456789ABCDEF";
    var numPart = hex.substr(1);
    var idx = 0;
    while (idx < numPart.length) {
        var power = numPart.length - idx - 1;
        var num = digits.indexOf(numPart.charAt(idx));
        total += Math.round(num * Math.pow(16, power));
        idx++;
    }
    return total;
}

function parseFloat(text: String) {
    var integerPortion: String = "";
    var decimalPortion: String = "";
    var split: Array<String> = text.split(".");
    integerPortion = split[0];
    decimalPortion = split[1];
    var totalValue: Float = 0;
    var isNegative = false;
    Engine.forCount(integerPortion.length, function (idx: Int) {
        var pos = integerPortion.length - 1 - idx;
        if (pos == 0 && integerPortion.charAt(pos) == "-") {
            isNegative = true;
            totalValue = totalValue * -1;
            return true;
        }
        var num = parseDigit(integerPortion.charAt(pos));
        totalValue += num * Math.pow(10, idx);
        return true;
    }, []);
    if (decimalPortion != null) {
        Engine.forCount(decimalPortion.length, function (idx: Int) {
            var num = parseDigit(decimalPortion.charAt(idx));
            totalValue += num * Math.pow(10, -(idx + 1));
            return true;
        }, []);
    }
    return totalValue;
}

function syntaxError(text: String, curr: Int): { text: String, color: Int, error: Bool, length: Int } {
    var errorMessage: String = [
        "Error Rendering Text: \nUnexpected character ",
        ("\"" + text.charAt(curr) + "\""),
        "\nat character position ", curr.toString()].join("");
    Engine.log(errorMessage, 0xFFC300);
    return {
        error: true,
        color: 0xFF0000,
        text: errorMessage
    };
}

function parseTag(text: String, curr: Int): { text: String, color: Int, error: Bool, length: Int } {
    var color = 0;
    var content = "";

    if ("<" == text.charAt(curr)) { curr++; } else { return syntaxError(text, curr); }

    while (text.charAt(curr) == " ") { curr++; }

    if (text.charAt(curr) == "#") {
        var hexString = "#";
        var nums = "0123456789ABCDEFabcdef";
        curr++;
        while (nums.indexOf(text.charAt(curr)) >= 0) {
            hexString += text.charAt(curr);
            curr++;
        }
        color = parseHexCode(hexString);
    } else { return syntaxError(text, curr); }

    while (text.charAt(curr) == " ") { curr++; }

    if (text.charAt(curr) == ">") { curr++; } else { return syntaxError(text, curr); }

    while (text.charAt(curr) != "<") {
        if (text.charAt(curr) == "\\" && curr + 2 < text.length) {
            content += text.charAt(curr + 1);
            curr += 2;
        } else {
            content += text.charAt(curr);
            curr++;
        }
    }

    if (text.charAt(curr) == "<") { curr++; } else { return syntaxError(text, curr); };

    if (text.charAt(curr) == "/") { curr++; } else { return syntaxError(text, curr); };

    if (text.charAt(curr) == ">") { curr++; } else { return syntaxError(text, curr); };

    return { color: color, text: content, length: curr };
}

function parseText(text: String): Array<{ text: String, color: Int, error: Bool, length: Int }> {
    var nodes: Array<{ text: String, color: Int, error: Bool, length: Int }> = [];
    var curr = 0;
    var nodeIdx = 0;
    while (curr < text.length) {
        if (nodes[nodeIdx] == null) {
            nodes[nodeIdx] = {
                text: "",
                color: 0xFFFFFF,
                length: 0,
                error: false
            };
        }

        switch (text.charAt(curr)) {
            case "\\": {
                if (curr + 2 < text.length) {
                    nodes[nodeIdx].text += text.charAt(curr + 1);
                    nodes[nodeIdx].length += 1;
                    curr += 2;
                } else {
                    nodes.push(syntaxError(text, curr));
                    break;
                }
            };
            case "<": {
                nodeIdx++;
                var result = parseTag(text, curr);
                if (!result.error) {
                    curr = result.length;
                    nodes[nodeIdx] = result;
                    nodes[nodeIdx].color = result.color;
                    nodeIdx++;
                } else {
                    nodes[nodeIdx] = result;
                    break;
                }
            };
            default: {
                nodes[nodeIdx].text += text.charAt(curr);
                nodes[nodeIdx].length += 1;
                curr++;
            };

        }
    }
    return nodes;
}



function createColorShader(color) {
    var shader = new RgbaColorShader();
    shader.color = color;
    shader.redMultiplier = 1 / 3;
    shader.greenMultiplier = 1 / 2;
    shader.blueMultiplier = 1;
    return shader;
}


function renderText(
    text: String,
    sprites: Array<Sprite>,
    container: Container,
    options: { autoLinewrap: Int, delay: Int, x: Int, y: Int, owner: Entity, spacebetween: Int }
): { duration: Int, sprites: Array<Sprite> } {
    var parsed: Array<{ text: String, color: Float, error: Boolean, length: number }> = parseText(text);
    disposeSprites(sprites);

    sprites = [];
    var line = 0;
    var col = 0;

    function makeSprite(char: String, shaderOptions: { color: Int }) {
        if (options != null && options.autoLinewrap > 0 && options.autoLinewrap < col && !options.wordWrap) {
            col = 0;
            line++;
        }
        var sprite: Sprite = createSpriteFromCharacter(char);
        var spacebetween = 0;
        if (options != null && options.spacebetween != null) {
            spacebetween = options.spacebetween;
        }
        sprite.x = col * (6 + spacebetween);
        if (options != null && options.x != null) {
            sprite.x += options.x;
        }
        sprite.y = line * 10;
        if (options != null && options.y != null) {
            sprite.y += options.y;
        }
        var shader: RgbaColorShader = createColorShader(shaderOptions.color);
        sprite.addShader(shader);
        return sprite;
    }

    Engine.forEach(parsed, function (node: {
        text: String, color: Int, error: Boolean, length: number
    }, _: Int) {
        Engine.forCount(node.text.length, function (idx: Int) {
            var char: String = node.text.charAt(idx);
            if (char == "\n") {
                line++;
                col = 0;
            } else {
                var sprite = makeSprite(char, { color: node.color });
                sprites.push(sprite);
                col++;
            }
            return true;
        }, []);
        return true;
    }, []);

    var owner = self;
    if (options.owner != null) {
        owner = options.owner;
    }

    if (options.delay != null && options.delay > 0) {
        Engine.forEach(sprites, function (sprite: Sprite, idx: Int) {
            owner.addTimer(idx * options.delay, 1, function () {
                container.addChild(sprite);
            }, { persistent: true });
            return true;
        }, []);

        return { sprites: sprites, duration: sprites.length * options.delay };
    } else {
        Engine.forEach(sprites, function (sprite: Sprite, _idx: Int) {
            container.addChild(sprite);
            return true;
        }, []);

        return { sprites: sprites, duration: -1 };
    }
}

function renderLines(lines: Array<String>,
    sprites: Array<Sprite>,
    container: Container,
    options: { delay: Int, x: Int, y: Int }): { duration: Int, sprites: Array<Sprite>, owner: Entity } {
    var renderData = renderText(lines.join("\n"), sprites, container, { autoLinewrap: false, delay: delay, x: options.x, y: options.y, owner: options.owner });
    return renderData;
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
        if (GraphicsSettings.damageHudPosition == "top") {
            // Make Top HUD specific changes here
            sprite.y = 320 + yOffset;
        } else {
            sprite.y = 32 + yOffset;
        }
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
    var jump = player.addStatusEffect(StatusEffectType.JUMP_SPEED_MULTIPLIER, 1.2, { tag: STATUS_TAG });
    var doubleJump = player.addStatusEffect(StatusEffectType.DOUBLE_JUMP_SPEED_MULTIPLIER, 1.2, { tag: STATUS_TAG });
    var fastFall = player.addStatusEffect(StatusEffectType.FAST_FALL_SPEED_MULTIPLIER, 1.2, { tag: STATUS_TAG });
    var runSpeed = player.addStatusEffect(StatusEffectType.RUN_SPEED_ACCELERATION_MULTIPLIER, 1.5, { tag: STATUS_TAG });
    var runSpeedCap = player.addStatusEffect(StatusEffectType.RUN_SPEED_CAP_MULTIPLIER, 1.5, { tag: STATUS_TAG });
    var dash = player.addStatusEffect(StatusEffectType.DASH_SPEED_MULTIPLIER, 1.5, { tag: STATUS_TAG });

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
    var damage = player.addStatusEffect(StatusEffectType.HITBOX_DAMAGE_MULTIPLIER, 1.1, { tag: STATUS_TAG });
    var hitstun = player.addStatusEffect(StatusEffectType.ATTACK_HITSTUN_MULTIPLIER, 1.1, { tag: STATUS_TAG });
    var knockback = player.addStatusEffect(StatusEffectType.ATTACK_KNOCKBACK_MULTIPLIER, 1.1, { tag: STATUS_TAG });

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
    // var rainbow = [0xe81416, 0xffa500, 0xfaeb36, 0x79c314, 0x487de7, 0x4b369d, 0x70369d];
    // Engine.forEach(rainbow, function (color: Int, idx: Int) {
    //     var glow = new GlowFilter();
    //     glow.color = color;
    //     player.addFilter(glow);
    //     return true;
    // }, []);

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
        var count = 0;
        var hitDealt = function (event: GameObjectEvent) {
            var attacker: Character = event.data.self;
            var currTime = match.getElapsedFrames();
            if (
                (attacker.inState(CState.STRONG_FORWARD_ATTACK)
                    || attacker.inState(CState.STRONG_DOWN_ATTACK)
                    || attacker.inState(CState.STRONG_UP_ATTACK))
                && (currTime - prevTime) > 100) {
                prevTime = currTime;
                count += 1;
                if (count == times) {
                    setMissionStatus(player, MISSION_SUCCESS);
                }
            }
        };

        player.addEventListener(GameObjectEvent.HIT_DEALT, hitDealt, { persistent: true });
        player.addTimer(duration, 1, function () {
            player.removeEventListener(GameObjectEvent.HIT_DEALT, hitDealt);
            if (count >= times) {
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
            if (event.data.self == player) {
                setMissionStatus(event.data.self, MISSION_SUCCESS);
            }
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

function displayMissionPrompt(mission: Array<String>) {

    var sprites: Array<Sprite> = [];
    var vfx: Vfx = match.createVfx(new VfxStats({
        x: camera.getViewportWidth() / 2,
        y: camera.getViewportHeight() / 2,
        spriteContent: getContent("text"),
        animation: "base",
        loop: true
    }), null);

    vfx.setX(vfx.getX() - vfx.getSprite().width / 2);
    camera.getForegroundContainer().addChildAt(vfx.getViewRootContainer(), 0);

    var glow = new GlowFilter();
    glow.color = 0xFFFFFF;
    glow.radius = 1;
    vfx.addFilter(glow);
    var renderData = renderText(mission, sprites, vfx.getViewRootContainer(), {
        delay: 3, autoLinewrap: false,
        x: 0, y: 0,
        owner: vfx
    });
    sprites = renderData.sprites;

    match.freezeScreen(renderData.duration + 90, [vfx]);

    vfx.addTimer(renderData.duration + 60, 1, function () {
        Engine.forEach(sprites, function (sprite: Sprite, idx: Int) {
            sprite.dispose();
            return true;
        }, []);
        vfx.destroy();

    }, { persistent: true });
}

function generateMission(displayString: String, missionFn, duration: Int, rewardFn, instruction: String) {
    return {
        displayString: displayString,
        missionFn: missionFn,
        duration: duration,
        rewardFn: rewardFn,
        instruction: instruction
    }
}

function runMission(mission: { displayString: Array<String>, duration: Int, missionFn: Any, rewardFn: Any, instruction: String }) {
    var p: Character = self.getOwner();
    globalController.exports.data.cooldown = true;
    displayMissionPrompt(mission.displayString);
    clearMissionData();
    mission.missionFn();
    var timeSprites = [];
    var curr = 0;

    var nodes = parseText(mission.instruction);
    var padding = 0;
    Engine.forEach(nodes, function (node, idx) {
        padding += node.text.length;
        return true;
    }, []);
    var textSprites = [];
    var renderData = renderText(mission.instruction, textSprites, camera.getForegroundContainer(), {
        x: camera.getViewportWidth(),
        y: 100,
        owner: p,
        delay: 3,
        spacebetween: 2,
    });
    textSprites = renderData.sprites;
    Engine.forEach(textSprites, function (sprite: Sprite, idx: Int) {
        sprite.x -= padding * (6 + 2);
        var glow = new GlowFilter();
        glow.color = 0x1c1c1c;
        glow.radius = 0.7;
        sprite.addFilter(glow);
        return true;
    }, []);


    p.addTimer(1, mission.duration, function () {
        curr += 1;
        var ts = renderTime(createTimeObject(mission.duration - curr), timeSprites, globalController.getViewRootContainer(), 32);
        var container = camera.getForegroundContainer();
        container.addChildAt(globalController.getViewRootContainer(), 0);
        timeSprites = ts;
    }, { persistent: true });

    p.addTimer(mission.duration, 1, function () {
        Engine.forEach(timeSprites, function (sprite: Sprite, _idx: Int) {
            sprite.dispose();
            return true;
        }, []);
        Engine.forEach(renderData.sprites, function (sprite: Sprite, _idx: Int) {
            sprite.dispose();
            return true;
        }, []);
        Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
            if (getMissionStatus(player) == MISSION_SUCCESS) {
                mission.rewardFn(player);
            }
            return true;
        }, []);

        p.addTimer(60 * 30, 1, function () {
            clearMissionData();
            globalController.exports.data.cooldown = false;
        }, { persistent: true });

    }, { persistent: true });

    var totalMissionTime = mission.duration;
    return totalMissionTime;
}


function enableMissionMode() {
    globalController.exports.data.missionStatus = [MISSION_PENDING, MISSION_PENDING, MISSION_PENDING, MISSION_PENDING];
    globalController.exports.data.missionData = [{}, {}, {}, {}];
    globalController.exports.data.missionStatusSprites = [null, null, null, null];
    globalController.exports.data.cooldown = false;



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

    var deal50Regen = generateMission(
        ["<#f1c40f>MISSION: </> <#e74c3c>Deal</> 50 damage",
            "<#28b463>REWARD:</> <#ff8c69>Regeneration</>",
            "<#d2b4de>TIME LIMIT:</> 20 Seconds"].join("\n"),
        function () { dealDamage(60 * 20, 50); },
        60 * 20,
        function (player: Character) { regenBuff(player, 60 * 10); },
        "<#e74c3c>Deal</> 50 damage");

    var noHitDefense = generateMission(
        ["<#f1c40f>MISSION: </> Don't get <#e74c3c>Hit</>",
            "<#28b463>REWARD:</> <#00bfff>Defense Buff</>",
            "<#d2b4de>TIME LIMIT:</> 15 Seconds"].join("\n"),
        function () { noHit(60 * 15); },
        60 * 15,
        function (player: Character) { defenseBuff(player, 60 * 10); },
        "Don't get <#e74c3c>Hit</>");

    var landStrongMobility = generateMission(
        ["<#f1c40f>MISSION: </> Land <#e74c3c>4 Strongs</>",
            "<#28b463>REWARD:</> <#00cc99>Mobility Buff</>",
            "<#d2b4de>TIME LIMIT:</> 20 Seconds"].join("\n"),
        function () { landStrongs(4, 60 * 20); },
        60 * 20,
        function (player: Character) { mobilityBuff(player, 60 * 10); },
        "Land <#e74c3c>4 Strongs</>");


    var landedParryCancel = generateMission(
        ["<#f1c40f>MISSION: </> Successfully <#e74c3c>Parry</> an attack",
            "<#28b463>REWARD:</> <#ff8c69>Jump Cancels</>",
            "<#d2b4de>TIME LIMIT:</> 15 Seconds"].join("\n"),
        function () { landedParry(60 * 15); },
        60 * 15,
        function (player: Character) { jumpCancels(player, 60 * 10); }
        , "<#e74c3c>Parry</> an attack");

    var landedSpikes = generateMission(
        ["<#f1c40f>MISSION: </> Land <#e74c3c>3 Spikes</>",
            "<#28b463>REWARD:</> <#FF0000>Attack Buff</>",
            "<#d2b4de>TIME LIMIT:</> 15 Seconds"].join("\n"),
        function () { landedSpikes(3, 60 * 15); },
        60 * 15,
        function (player: Character) { attackBuff(player, 60 * 10); },
        "Land <#e74c3c>3 Spikes</>");

    var missions = [noHitDefense, deal50Regen, landStrongMobility, landedParryCancel, landedSpikes];


    p.addTimer(60, -1, function () {
        if (globalController.exports.data.cooldown == false) {
            var chosenMission = Random.getChoice(missions);
            runMission(chosenMission);
        }
    }, { persistent: true });

}


function directionToAerial(player: Character) {
    var held = player.getHeldControls();
    var forward = (held.LEFT && player.isFacingLeft()) || (held.RIGHT && player.isFacingRight());
    var backward = (held.RIGHT && player.isFacingLeft()) || (held.LEFT && player.isFacingRight());
    var up = held.UP;
    var down = held.DOWN;

    if (held.hasRightStickAttackFlag()) {
        forward = forward || (held.RIGHT_STICK_LEFT && player.isFacingLeft()) || (held.RIGHT_STICK_RIGHT && player.isFacingRight());
        backward = backward || (held.RIGHT_STICK_RIGHT && player.isFacingLeft()) || (held.RIGHT_STICK_LEFT && player.isFacingRight());
        up = up || held.RIGHT_STICK_UP;
        down = down || held.RIGHT_STICK_DOWN;
    }

    if (up) {
        player.toState(CState.AERIAL_UP);
    } else if (down) {
        player.toState(CState.AERIAL_DOWN);
    } else if (forward) {
        player.toState(CState.AERIAL_FORWARD);
    } else if (backward) {
        player.toState(CState.AERIAL_BACK);
    } else {
        player.toState(CState.AERIAL_NEUTRAL);
    }
}


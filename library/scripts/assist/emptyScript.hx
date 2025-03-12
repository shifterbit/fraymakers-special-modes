// Runs on object init
var player1: Character = null;
var player1StatusId: Int = null;

var player2: Character = null;
var player2StatusId: Int = null;

var player3: Character = null;
var player3StatusId: Int = null;

var player4: Character = null;
var player4StatusId: Int = null;

function setupVariables() {
    Engine.forCount(match.getPlayers(), function (player: Character, _idx: Int) {
        if (player1 == null) {
            player1 = player;
        } else if (player2 == null) {
            player2 = player;
        } else if (player3 == null) {
            player3 = player;
        } else if (player4 == null) {
            player4 = player;
        }
        return true;
    }, []);
}


function updateGlows() {
    var player1Score = (2000 * player1.getScore()) - player1.getDamage();
    var player2Score = (2000 * player2.getScore()) - player2.getDamage();
    var player3Score = (2000 * player3.getScore()) - player3.getDamage();
    var player4Score = (2000 * player4.getScore()) - player4.getDamage();


    player1Glow.alpha = 0;
    player2Glow.alpha = 0;
    player3Glow.alpha = 0;
    player4Glow.alpha = 0;



    if (player1Score > player2Score && player1Score > player3Score && player1Score > player4Score) {
        player1Glow.alpha = 1;

    } else if (player2Score > player1Score && player2Score > player3Score && player2Score > player4Score) {
        player2Glow.alpha = 1;

    } else if (player3Score > player2Score && player3Score > player1Score && player3Score > player4Score) {
        player3Glow.alpha = 1;

    } else if (player4Score > player2Score && player4Score > player3Score && player4Score > player1Score) {
        player4Glow.alpha = 1;
    }
}



function calculateDistanceFromTarget(target: Character) {

    var targetLocation: Point = Point.create(target.getX() + self.getEcbFootX(), target.getY() - target.getEcbLeftHipY());
    var currentLocation: Point = Point.create(self.getX() + self.getEcbFootX(), self.getY() - self.getEcbLeftHipY());

    var res: Float = Math.abs(Math.getDistance(targetLocation, currentLocation));
    targetLocation.dispose();
    currentLocation.dispose();
    return res;

}


function healFriendsOnce(maxDistance: Int, healing: Int) {
    var owner: Character = self.getOwner();
    Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
        var isOwner: Bool = player == owner;
        var isOnTeam: Bool = isOwner || (player.getPlayerConfig().team == owner.getPlayerConfig().team);

        if (isOnTeam) {
            if (calculateDistanceFromTarget(player) <= maxDistance) {
                player.addDamage(-healing);
            }
        }
        return true;
    }, []);
}


// We dont have a timer here
function healFriends(maxDistance: Int, healing: Int) {
    var owner: Character = self.getOwner();
    Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
        var isOwner: Bool = player == owner;
        var isOnTeam: Bool = isOwner || (player.getPlayerConfig().team == owner.getPlayerConfig().team);


        if (isOnTeam) {
            if (calculateDistanceFromTarget(player) <= maxDistance) {
                player.addDamage(-healing);
            }
        }
        return true;
    }, []);
}


function healFriends(maxDistance: Int, repeats: Int, interval: Int, healing: Int) {
    var owner: Character = self.getOwner();
    Engine.forEach(match.getPlayers, function (player: Character, _idx: Int) {
        var isOwner: Bool = player == owner;
        var isOnTeam: Bool = !owner.getFoes().contains(player);


        if (isOnTeam) {
            self.addTimer(interval, repeats, function () {
                if (calculateDistanceFromTarget(player) <= maxDistance) {
                    player.addDamage(-healing);
                }
            }, { persistent: true });
        }
        return true;
    }, []);
}

function update() {

}
function onTeardown() {
}



var overrides = [
    "animation0" => [
        new HitboxStats({}), // override for hitbox0
        new HitboxStats({}) // override for hitbox1
    ],
        "animation2" => [
            new HitboxStats({}) // override for hitbox0
        ],
];


function applyOverrides(player: Character, overrides: StringMap) {
    var hitboxes: Array<HitboxStats> = overrides.get(player.getAnimation());
    Engine.forEach(hitboxes, function (stats: HitboxStats, idx: Int) {
        if (stats != null) {
            player.updateHitboxStats(idx, stats);
        }
    }, []);


}

function calculateDistanceFromTarget(target: Character) {
    var targetLocation: Point = Point.create(target.getX() + self.getEcbFootX(), target.getY() - target.getEcbLeftHipY());
    var currentLocation: Point = Point.create(self.getX() + self.getEcbFootX(), self.getY() - self.getEcbLeftHipY());

    var res: Float = Math.abs(Math.getDistance(targetLocation, currentLocation));
    targetLocation.dispose();
    currentLocation.dispose();
    return res;

}

function healFriends(maxDistance: Int, repeats: Int, interval: Int, healing: Int) {
    var owner: Character = self.getOwner();
    Engine.forEach(match.getPlayers(), function (player: Character, _idx: Int) {
        var isOwner: Bool = player == owner;
        var isOnTeam: Bool = isOwner || (player.getPlayerConfig().team == owner.getPlayerConfig().team);

        if (isOnTeam) {
            self.addTimer(interval, repeats, function () {
                if (calculateDistanceFromTarget(player) <= maxDistance) {
                    player.addDamage(-healing);
                }
            }, { persistent: true });
        }
        return true;
    }, []);
}
var self: Character;


function initialize() {
    if (self.getCostumeIndex() == 0) {
        costumeselected = true;
    }

    self.addEventListener(GameObjectEvent.LINK_FRAMES, handleLinkFrames, { persistent: true });

    if (self.getCostumeIndex() == 25) {
        self.updateCharacterStats({
            gravity: 0.5,
            baseScaleX: 2.0,
            baseScaleY: 2.0,
        });
    }

    if (self.getCostumeIndex() == 25 && self.getLives() == 1) {

        self.updateHitboxStats(0,
            {
                damage: 40,
                angle: 60,
                hitSoundOverride: "swordM",
                baseKnockback: 80,
                knockbackGrowth: 40,
                hitstop: 3,
                selfHitstop: -1,
                limb: AttackLimb.FIST
            });
    }

}
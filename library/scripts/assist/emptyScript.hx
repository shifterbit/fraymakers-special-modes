// Runs on object init
function initialize() {


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
    Engine.forEach(match.getPlayers, function (player: Character, _idx: Int) {
        var isOwner: Bool = player == owner;
        var isOnTeam: Bool = isOwner || player.getPlayerConfig().team == owner.getPlayerConfig().team;

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
var enabled = self.makeBool(false);

function vampire(event: GameObjectEvent) {
 
    event.data.self.addDamage(Math.ceil(event.data.hitboxStats.damage / -2));

}

function enableVampireMode() {
    var players = match.getPlayers();
    Engine.log(players);
    Engine.forEach(players, function (player: Character, _idx: Int) {
        player.addEventListener(GameObjectEvent.HIT_DEALT, vampire, { persistent: true });
        return true;
    }, []);

}


// Runs on object init
function initialize() {
    Engine.log("Hello WOrld");
}

function update() {
    var player: Character = self.getOwner();
    player.setAssistCharge(0);
    if (match.getPlayers().length > 1 && !enabled.get()) {
        enabled.set(true);
        enableVampireMode();
    }
}
function onTeardown() {
}

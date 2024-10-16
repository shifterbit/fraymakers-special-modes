var enabled = self.makeBool(false);

Engine.log("Hello WOrld");
function turbo(event: GameObjectEvent) {
    var p: Character = event.data.self;
    p.updateAnimationStats({ interruptible: true });
}

function enableVampireMode() {
    var players = match.getPlayers();
    Engine.log(players);
    Engine.forEach(players, function (player: Character, _idx: Int) {
        Engine.log(player);
        player.addEventListener(GameObjectEvent.HIT_DEALT, turbo, { persistent: true });
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

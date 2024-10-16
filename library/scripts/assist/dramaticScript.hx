var enabled = self.makeBool(false);


function visuals(event: GameObjectEvent) {
    Engine.log("running visuals");
    var foe: Character = event.data.foe;
    var darken = new HsbcColorFilter();
    darken.brightness = 0.1;
    darken.saturation = 0;


    camera.addForcedTarget(foe);
    camera.setMode(1);
    event.data.self.addTimer(15, 1, function () {
        camera.deleteForcedTarget(foe);
        camera.addTarget(foe);
        camera.setMode(0);
    }, {});
}

function enableDramaticMode() {
    var players = match.getPlayers();
    Engine.log(players);
    Engine.forEach(players, function (player: Character, _idx: Int) {
        Engine.log(player);
        player.addTimer(1, -1,
            function () {
                player.addEventListener(GameObjectEvent.HIT_DEALT, visuals, { persistent: true });
            }
            , { persistent: true });
        return true;
    }, []);

}

// Runs on object init
function initialize() {
}

function update() {
    var player: Character = self.getOwner();
    player.setAssistCharge(0);
    if (match.getPlayers().length > 1 && !enabled.get()) {
        enabled.set(true);
        enableDramaticMode();
    }
}
// function onTeardown() {
// }

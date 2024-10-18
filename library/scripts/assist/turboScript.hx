var enabled = self.makeBool(false);

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
    var player: Character = self.getOwner();
    var container: Container = player.getDamageCounterContainer();
    var resource: String = player.getAssistContentStat("spriteContent") + "turbo";
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
        enableTurboMode();
    }
}
function onTeardown() {
}

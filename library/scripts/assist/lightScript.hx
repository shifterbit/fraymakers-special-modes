var enabled = self.makeBool(false);

// function makeLight(obj: GameObject) {
//     var gravity = obj.getGameObjectStat("gravity");
//     obj.updateGameObjectStats({gravity: gravity / 2});

// }

function enableLightMode() {
    Engine.forEach(match.getCharacters(), function (player: Character, _idx: Int) {
        // player.addStatusEffect(StatusEffectType.GRAVITY_MULTIPLIER, 0.5);
        // player.addEventListener(GameObjectEvent.PROJECTILE_CREATED, function (event: GameObjectEvent) {
        //     Engine.forEach(match.getProjectiles(), function (projectile: Projectile, _idx: Int) {
        //         makeLight(projectile);
        //         return true;
        //     }, []);

        // }, { persistent: true });
        return true;
    }, []);
    var player: Character = self.getOwner();
    var container: Container = player.getDamageCounterContainer();
    var resource: String = player.getAssistContentStat("spriteContent") + "light";
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
        enableLightMode();
    }
}
function onTeardown() {
}

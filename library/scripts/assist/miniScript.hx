var enabled = self.makeBool(false);

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
    var player: Character = self.getOwner();
    var container: Container = player.getDamageCounterContainer();
    var resource: String = player.getAssistContentStat("spriteContent") + "mini";
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
        enableMiniMode();
    }
}
function onTeardown() {
}

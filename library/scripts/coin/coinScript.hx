// API Script for Character Template Projectile

var X_SPEED = 1 + Random.getFloat(0,2.5); // X speed of water
var Y_SPEED = -7; // Y Speed of water

self.exports.coin = true;
// Instance vars
var life = self.makeInt(60 * 4);
var originalOwner = null;

function initialize() {
	self.addEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit, { persistent: true });
	// self.addEventListener(GameObjectEvent.HIT_DEALT, onHit, { persistent: true });
	self.addTimer(90, 1, function () {
		self.setOwner(null);
	}, {persistent: true});



	//Engine.log(self.getOwner().getEcbHeadY());
	self.setY(self.getY() + self.getOwner().getEcbHeadY());
	self.setCostumeIndex(self.getOwner().getCostumeIndex());



	// Set up horizontal reflection
	//Common.enableReflectionListener({ mode: "X", replaceOwner: true });
	Common.disableReflectionListener();
	self.setState(PState.ACTIVE);

	self.setXSpeed(X_SPEED);
	self.setYSpeed(Y_SPEED);
}

function onGroundHit(event) {
	X_SPEED = X_SPEED / 1.8;
	Y_SPEED = Y_SPEED / 1.5;
	self.setXSpeed(X_SPEED);
	self.setYSpeed(Y_SPEED);
	self.setOwner(null);
}

function onHit(event) {
	Engine.log("landed hit");
	var p: Projectile = self;
	self.destroy();
	self.dispose();
	self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
	self.dispose();
	self.toState(PState.DESTROYING);
}

function update() {
	
	if (self.inState(PState.ACTIVE)) {
		life.dec();
		if (life.get() <= 0) {
			self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
			self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
			self.destroy();
		}
	}
}

function onTeardown() {
	self.removeEventListener(EntityEvent.COLLIDE_FLOOR, onGroundHit);
	self.removeEventListener(GameObjectEvent.HIT_DEALT, onHit);
}
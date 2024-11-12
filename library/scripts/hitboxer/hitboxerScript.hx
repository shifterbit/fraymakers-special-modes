// API Script for Character Template Projectile

var X_SPEED = 0; // X speed of water
var Y_SPEED = 0; // Y Speed of water

// Instance vars
var life = self.makeInt(60 * 5);
var originalOwner = null;

function initialize() {


	self.setCostumeIndex(self.getOwner().getCostumeIndex());

	self.setState(PState.ACTIVE);

	self.setXSpeed(X_SPEED);
	self.setYSpeed(Y_SPEED);
}


function update() {
	self.setX(self.getOwner().getX());
	self.setY(self.getOwner().getY());
}

function onTeardown() {

}
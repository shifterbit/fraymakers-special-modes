// API Script for Character Template Projectile

var X_SPEED = 7; // X speed of water
var Y_SPEED = -7; // Y Speed of water

// Instance vars
var life = self.makeInt(60 * 5);
var originalOwner = null;
self.exports.dummy = true;

function initialize() {
	self.setState(PState.ACTIVE);
}



function update() {
}

function onTeardown() {
}


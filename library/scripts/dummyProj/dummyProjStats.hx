// Animation stats for Character Template Projectile
{
	spriteContent: self.getResource().getContent("dummyProj"),
	stateTransitionMapOverrides: [
		PState.ACTIVE => {
			animation: "projectileSpawn"
		},
		PState.DESTROYING => {
			animation: "projectileDestroy"
		}
	],	
	gravity: 0,
	shadows: true,
	ghost: true,
	friction: 0,
	groundSpeedCap: 11,
	aerialSpeedCap: 1,
	aerialFriction: 0,
	terminalVelocity: 20, 
	floorHeadPosition: 15,
	floorHipWidth: 16,
	floorHipXOffset: 0,
	floorHipYOffset: 0,
	floorFootPosition: 0,
	aerialHeadPosition: 15,
	aerialHipWidth: 16,
	aerialHipXOffset: 0,
	aerialHipYOffset: 0,
	aerialFootPosition: 0
}
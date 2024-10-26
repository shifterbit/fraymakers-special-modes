// Hitbox stats for Character Template Projectile
{
	projectileSpawn: {
	},
	projectileIdle: {
		hitbox0: { damage: 0, knockbackGrowth: 0, baseKnockback: 0, angle: 0, reversibleAngle: false, directionalInfluence: false, reflectable: true }
	},
	gold: {
		hitbox0: {  damage: 0, knockbackGrowth: 0, baseKnockback: 0, angle: 0, reversibleAngle: false, directionalInfluence: false, reflectable: true, flinch: false, sheildable: false, hitEffectOverride: self.getResource().getContent("coinProj") + "#vfx", hitSoundOverride: self.getResource().getContent("coinSound") }
	},
	silver: {
		hitbox0: { damage: 0, knockbackGrowth: 0, baseKnockback: 0, angle: 0, reversibleAngle: false, directionalInfluence: false, reflectable: true, flinch: false, sheildable: false, hitEffectOverride: self.getResource().getContent("coinProj") + "#vfx", hitSoundOverride: self.getResource().getContent("coinSound") }
	},
	bronze: {
		hitbox0: { damage: 0, knockbackGrowth: 0, baseKnockback: 0, angle: 0, reversibleAngle: false, directionalInfluence: false, reflectable: true, flinch: false, sheildable: false, hitEffectOverride: self.getResource().getContent("coinProj") + "#vfx", hitSoundOverride: self.getResource().getContent("coinSound") }
	},

	projectileDestroy: {
	}
}

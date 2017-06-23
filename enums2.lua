Lists = {
	--Custom Pedestals
	Pedestals = {
		PEDESTAL_DEFAULT = 0,
		NUM_PEDESTALS = 1,
		ANIMFILE = "gfx/Items/Pick Ups/Pedestals/animation.anm2",
	},
	--Enemy Subtypes
	EnemySubTypes = {
	},
	--Tear subs
	TearSubTypes = {
	},
	--Helper Callbacks
	Callbacks = {
		ENTITY_SPAWN = 1
	},
	--Default unlockflags
	DefUnlockFlags = {
		Satan = false,
		Isaac = false,
		Lamb = false,
		BlueBaby = false,
		Greed = false,
		Greedier = false,
		BossRush = false,
		Mom = false,
		Heart = false,
		Delirium = false,
		MegaSatan = false,
		Hush = false,
		Ezekiel = false,
	},
	--Eternal jumping workaround
	JumpVariant = {
	},
	--functiontypes
	fnTypes = {
		UPDATE = "updateFns",
		INIT = "initFns",
		ANIM = "animFns",
		EVENT = "eventFns"
	}
}

return Lists
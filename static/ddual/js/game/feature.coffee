window.Brew.feature_def = 
	BLOOD:
		name: "Blood"
		color: Brew.colors.blood
		# bgcolor: Brew.colors.blood
		intensity: 0.5
		
	BRAINS:
		name: "Brains"
		color: Brew.colors.light_blue
		intensity: 0.5

	PLAYER_PAIR:
		name: "other player"
		group: null
		code: '@'
		color: Brew.colors.light_blue
		intensity: 0.5

	MONSTER_PAIR:
		name: "ghost monster"
		group: null
		code: 'X'
		color: Brew.colors.light_blue
		intensity: 0.5

	PROJ_ENTANGLE:
		name: "Entangler"
		group: "Animation"
		code: '\"'
		color: Brew.colors.light_blue
		bgcolor: null

	PROJ_FORCEBOLT:
		name: "Frostbolt"
		group: "Animation"
		code: '*'
		color: Brew.colors.green
		bgcolor: null
		light_source: Brew.colors.green

	PROJ_MONSTERBOLT:
		name: "Arrow or something"
		group: "Animation"
		code: '*'
		color: Brew.colors.red
		bgcolor: null

	PROJ_FIREBALL:
		name: "Fireball"
		group: "Animation"
		code: '*'
		color: Brew.colors.hf_orange
		bgcolor: null

	PROJ_FIREBALL_TRAIL:
		name: "Fireball Trail"
		group: "Animation"
		code: Brew.unicode.block_fade1
		color: Brew.colors.normal
		bgcolor: null

	TILE_FLASH:
		name: "Tile Flash"
		group: "Animation"
		code: Brew.unicode.block_fade2
		color: Brew.colors.white
		bgcolor: null

	PROJ_CHARGE:
		name: "Charge"
		group: "Animation"
		code: '@'
		color: Brew.colors.white
		intensity: 1.0

	FLAMES:
		name: "Flames"
		group: "Fire"
		code: '^'
		color: Brew.colors.hf_orange
		intensity: 1.0
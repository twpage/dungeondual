window.Brew.monster_def = 
	PLAYER:
		name: ["Griff", "Todd", "Hero", "Donut", "Carl"].random()
		group: "player"
		code: '@'
		color: Brew.colors.white # hf_orange
		light_source: Brew.colors.half_white
		sight_radius: 20
		rank: 0
		attack_range: 1
		hp: 5
		min_depth: 100

	CLOCK_SPIDER:
		name: "Clock Spider"
		group: "Spider"
		description: "Creepy crawly!"
		code: 's'
		color: Brew.colors.white
		hp: 2
		damage: 1
		flags: []
		rarity: 10
		min_depth: 0
		
	GIANT_SPIDER:
		name: "Giant Spider"
		group: "Spider"
		description: "Creepy crawly!"
		code: 's'
		color: Brew.colors.green
		hp: 3
		damage: 1
		flags: [Brew.flags.weapon_poison]
		rarity: 5
		min_depth: 0

	KOBOLD:
		name: "Kobold"
		group: "Kobold"
		description: "A denizen of dark caves, it wields a crude club."
		code: 'k'
		color: Brew.colors.white
		hp: 2
		damage: 1
		flags: []
		attack_range: 1
		rarity: 15
		min_depth: 0

	KOBOLD_ARCHER:
		name: "Smart Kobold"
		group: "Kobold"
		description: "A denizen of dark caves, in recent times Kobolds have begun to craft crude bows and become suspiciously intelligent."
		code: 'k'
		color: Brew.colors.violet
		hp: 1
		damage: 1
		flags: [Brew.flags.keeps_distance]
		attack_range: 7
		rarity: 5
		min_depth: 0

	BANDIT:
		name: "Bandit"
		group: "Bandit"
		description: "A scrubby-looking bandit."
		code: 'b'
		color: Brew.colors.white
		hp: 3
		damage: 2
		rarity: 15
		min_depth: 1

	ORC:
		name: "Orc"
		group: "Orc"
		description: "A green-skinned smelly orc. Who brought them to these caves?"
		code: 'o'
		color: Brew.colors.white
		hp: 3
		damage: 3
		rarity: 15
		min_depth: 1

	BANDIT_LEADER:
		name: "Bandit Leader"
		group: "Bandit"
		description: "A slightly richer-looking bandit."
		code: 'b'
		color: Brew.colors.green
		flags: [Brew.flags.flees_when_wounded]
		hp: 5
		damage: 2
		rarity: 5
		min_depth: 2

	BANDIT_WARLORD:
		name: "Bandit Warlord"
		group: "Bandit"
		description: "Looks like a king among bandits."
		code: 'b'
		color: Brew.colors.light_blue
		flags: [Brew.flags.keeps_distance, Brew.flags.weapon_poison]
		attack_range: 7
		hp: 8
		damage: 4
		rarity: 5
		min_depth: 3

	VICIOUS_ORC:
		name: "Vicious Orc"
		group: "Orc"
		description: "A vicious-looking orc. Who brought them to these caves?"
		code: 'o'
		color: Brew.colors.green
		hp: 4
		damage: 4
		rarity: 15
		min_depth: 3

	FIRE_TOAD:
		name: "Fire Toad"
		group: "Toad"
		description: "A huge firey-red toad."
		code: 't'
		color: Brew.colors.red
		flags: [Brew.flags.keeps_distance, Brew.flags.weapon_burning]
		attack_range: 7
		hp: 4
		damage: 1
		rarity: 7
		min_depth: 3

	ORC_SHAMAN:
		name: "Orc Shaman"
		group: "Orc"
		description: "An older orc decorated with war paint and what you hope are animal bones."
		code: 'o'
		color: Brew.colors.light_blue
		flags: [Brew.flags.keeps_distance]
		attack_range: 7
		hp: 6
		damage: 2
		rarity: 10
		min_depth: 3

	ORC_CHAMPION:
		name: "Orc Champion"
		group: "Orc"
		description: "That's the biggest damn orc you've ever seen! What twisted magic has wrought such a creature?"
		code: 'o'
		color: Brew.colors.yellow
		flags: []
		attack_range: 1
		hp: 12
		damage: 6
		rarity: 5
		min_depth: 4

	TROLL:
		name: "Cave Troll"
		group: "Troll"
		description: "Even stooped over, the head of this creature brushes the top of the cave. A heavy chain is in its hands."
		code: 'T'
		color: Brew.colors.white
		flags: []
		attack_range: 1
		hp: 16
		damage: 6
		rarity: 15
		min_depth: 6

	CUBE:
		name: "Gelatinous Cube"
		group: "Cube"
		description: "A quivering mass of goo."
		code: 'C'
		color: Brew.colors.light_blue
		flags: [Brew.flags.weapon_poison]
		attack_range: 1
		hp: 20
		damage: 2
		rarity: 10
		min_depth: 7

	BALROG:
		name: "Balrog"
		group: "Balrog"
		description: "An ancient evil that frightens even orcs and trolls. It is wreathed in fire and shadow."
		code: 'B'
		color: Brew.colors.red
		flags: [Brew.flags.weapon_burning]
		attack_range: 1
		hp: 20
		damage: 8
		rarity: 5
		min_depth: 8

	TURRET:
		name: "Arrow Turret"
		group: "Turret"
		code: Brew.unicode.filled_circle
		color: Brew.colors.light_blue
		flags: [Brew.flags.immobile]
		attack_range: 7
		hp: 6

	LICH:
		name: "Lich"
		group: "Lich"
		code: 'L'
		description: "The withered and re-animated remains of a powerful wizard. Commands the undead and can summon swarms of zombies."
		color: Brew.colors.yellow
		flags: [Brew.flags.keeps_distance, Brew.flags.summons_zombies]
		attack_range: 7
		hp: 10
		damage: 2
		rarity: 10
		min_depth: 4
		
	ZOMBIE:
		name: "Zombie"
		group: "Zombie"
		code: "Z"
		description: "The walking dead!! Gross."
		color: Brew.colors.brown
		flags: []
		attack_range: 1
		hp: 2
		damage: 2
		rarity: 0
		min_depth: 100

	ZOMBIE_LIMB:
		name: "Zombie Limb"
		group: "Zombie"
		code: "z"
		description: "An animated zombie hand. Gross."
		color: Brew.colors.brown
		flags: []
		attack_range: 1
		hp: 1
		damage: 1
		rarity: 0
		min_depth: 100

	TIME_MASTER:
		name: "The Time Master"
		group: "BOSS"
		description: "He's the main bad guy. I guess?"
		code: '@'
		color: Brew.colors.hf_orange
		flags: [Brew.flags.weapon_poison, Brew.flags.keeps_distance, Brew.flags.flees_when_wounded]
		attack_range: 7
		hp: 30
		damage: 6
		rarity: 0
		min_depth: 100


	AGENT_TERRAIN_TRAVEL:
		agent: true
		name: "Newtonian Terrain"
		code: '0'
		color: Brew.colors.white
		min_depth: 100

	AGENT_FEATURE_TRAVEL:
		agent: true
		name: "Newtonian Feature"
		code: '0'
		color: Brew.colors.hf_orange
		min_depth: 100


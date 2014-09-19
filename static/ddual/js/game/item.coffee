window.Brew.item_def = 

	##############################
	## FLASKS
	##############################
	FLASK_FIRE:
		name: "Flask"
		flaskType: Brew.flaskTypes.fire
		group: Brew.groups.FLASK
		color: Brew.colors.yellow

	FLASK_HEALTH:
		name: "Flask"
		flaskType: Brew.flaskTypes.health
		group: Brew.groups.FLASK
		color: Brew.colors.yellow

	FLASK_WEAKNESS:
		name: "Flask"
		flaskType: Brew.flaskTypes.weakness
		group: Brew.groups.FLASK
		color: Brew.colors.yellow

	FLASK_MIGHT:
		name: "Flask"
		flaskType: Brew.flaskTypes.might
		group: Brew.groups.FLASK
		color: Brew.colors.yellow

	FLASK_VIGOR:
		name: "Flask"
		flaskType: Brew.flaskTypes.vigor
		group: Brew.groups.FLASK
		color: Brew.colors.yellow

	FLASK_INVISIBLE:
		name: "Flask"
		flaskType: Brew.flaskTypes.invisible
		group: Brew.groups.FLASK
		color: Brew.colors.yellow

	##############################
	## ARMOR
	##############################

	ARMOR_LEATHER:
		name: "Leather Armor"
		group: Brew.groups.ARMOR
		color: Brew.colors.yellow
		description: "It's better than nothing! Smells like cows."
		block: 1
		min_depth: 0

	ARMOR_CHAIN:
		name: "Chain Mail"
		group: Brew.groups.ARMOR
		color: Brew.colors.yellow
		description: "Finely crafted chainmail, better than any you will find at the renaissance fair."
		block: 2
		min_depth: 2
		
	ARMOR_SPLINT:
		name: "Splint Mail"
		group: Brew.groups.ARMOR
		color: Brew.colors.yellow
		description: "Strips of metal woven onto sturdy leather armor. Flexible yet strong. According to the D&D manual, at least."
		block: 3
		min_depth: 3
		
	ARMOR_PLATE:
		name: "Plate Mail"
		group: Brew.groups.ARMOR
		color: Brew.colors.yellow
		description: "This is totally the best armor in the game."
		block: 4
		min_depth: 5

	##############################
	## HATS
	##############################

	HAT_WIZARD:
		name: "Wizard Hat"
		group: Brew.groups.HAT
		color: Brew.colors.violet
		description: "You put on your wizard hat!"

	HAT_WINGED_HELM:
		name: "Winged Helm"
		group: Brew.groups.HAT
		color: Brew.colors.yellow
		description: "You look like a damned viking."
		
	HAT_GOGGLES:
		name: "Pair of Science Goggles"
		group: Brew.groups.HAT
		color: Brew.colors.green
		description: "Zee goggles, zey do nozzink!!"

	GLADIATOR_HELM:
		name: "Glatiator Helm"
		group: Brew.groups.HAT
		color: Brew.colors.yellow
		description: "ARE YOU NOT ENTERTAINED?"
		
	##############################
	## WEAPONS
	##############################

	WPN_DAGGER:
		name: "Dagger"
		group: Brew.groups.WEAPON
		color: Brew.colors.yellow
		description: "Use the pointy end."
		flags: []
		damage: 1
		min_depth: 0

	WPN_SPEAR:
		name: "Spear"
		group: Brew.groups.WEAPON
		color: Brew.colors.yellow
		description: "A long spear, can pierce through multiple enemies."
		flags: [Brew.flags.weapon_pierce]
		damage: 2
		min_depth: 0

	WPN_AXE:
		name: "Axe"
		group: Brew.groups.WEAPON
		color: Brew.colors.yellow
		description: "A medium-sized axe, capable of damaging surrounding foes."
		flags: [Brew.flags.weapon_smash]
		damage: 2
		min_depth: 1

	WPN_HAMMER:
		name: "Hammer"
		group: Brew.groups.WEAPON
		color: Brew.colors.yellow
		description: "A massive crushing implement, has a chance to stun enemies."
		flags: [Brew.flags.weapon_stun_chance]
		damage: 2
		min_depth: 1

	WPN_SWORD:
		name: "Sword"
		group: Brew.groups.WEAPON
		color: Brew.colors.yellow
		description: "A sharp steel blade that can slice through the toughest armor."
		flags: []
		damage: 3
		min_depth: 1

	WPN_MORNINGSTAR:
		name: "Morning Star"
		group: Brew.groups.WEAPON
		color: Brew.colors.yellow
		description: "It's a big ol spiked ball on the end of a chain. Capable of damaging surrounding foes."
		flags: [Brew.flags.weapon_smash]
		damage: 4
		min_depth: 4

	WPN_PIKE:
		name: "Pike"
		group: Brew.groups.WEAPON
		color: Brew.colors.yellow
		description: "A weapon of war, can pierce through multiple enemies."
		flags: [Brew.flags.weapon_pierce]
		damage: 5
		min_depth: 4

	WPN_BROADSWORD:
		name: "Broadsword"
		group: Brew.groups.WEAPON
		color: Brew.colors.yellow
		description: "An enourmous steel blade that requires two hands to swing. It's damage is unrivaled."
		flags: []
		damage: 6
		min_depth: 6

	WPN_WARHAMMER:
		name: "War Hammer"
		group: Brew.groups.WEAPON
		color: Brew.colors.yellow
		description: "A massive crushing implement, has a chance to stun enemies."
		flags: [Brew.flags.weapon_stun_chance]
		damage: 5
		min_depth: 6

	# WPN_FIRESWORD:
	# 	name: "Flaming Sword"
	# 	group: Brew.groups.WEAPON
	# 	color: Brew.colors.yellow
	# 	description: "An enourmous steel blade wreathed in flame. Somehow it doesn't burn you."
	# 	flags: [Brew.flags.weapon_burning]
	# 	damage: 6
	# 	min_depth: 8
		
	##############################
	## OTHER
	##############################

	TIME_ORB:
		name: "Time Orb"
		group: Brew.groups.TIMEORB
		color: Brew.colors.yellow
		description: "Enables communication across realms"
		min_depth: 100

	INFO_POINT:
		name: "Info"
		group: Brew.groups.INFO
		# code: "?"
		color: Brew.colors.pink
		min_depth: 100

	ARMY_CORPSE:
		name: "Corpse of a brave soldier."
		group: Brew.groups.CORPSE
		# code: "?"
		description: "The remains of a King's army soldier."
		color: Brew.colors.normal
		min_depth: 100

window.Brew.terrain_def = 
	EMPTY:
		name: 'Empty'
		code: ' '
		color: Brew.colors.normal

	WALL:
		name: 'Wall'
		code: '#'
		
		color: Brew.colors.dark_grey
		color_randomize: [5, 0, 0]

		bgcolor: [150, 150, 150]
		bgcolor_randomize: [0, 5, 5]
		
		blocks_walking: true
		blocks_vision: true
		blocks_flying: true

		description: "rough-hewn rock wall"
		
	WALL_TORCH:
		name: 'Wall Torch'
		code: '^'
		
		bgcolor: [150, 150, 150]
		bgcolor_randomize: [0, 5, 5]
		color: Brew.colors.torch
		light_source: Brew.colors.torch

		blocks_walking: true
		blocks_vision: true
		blocks_flying: true

		description: "a flickering torch"

	FLOOR:
		name: 'Cavern Floor'
		code: '.'
		color: Brew.colors.normal
		bgcolor: Brew.colors.dark_grey
		bgcolor_randomize: [0, 8, 8]
		show_gore: true

		description: "smoothed cavern floor"
		walkover: "You step onto the weathered cavern floor"

	STONE:
		name: 'Crumbling Stone'
		code: ["'", "`"]
		color: Brew.colors.normal
		bgcolor: Brew.colors.dark_grey
		bgcolor_randomize: [0, 0, 2]
		show_gore: true

		description: "rough stone floor"
		walkover: "Rocks and grit crunch under your feet"

	SHALLOW_POOL:
		name: 'Shallow Water'
		code: '~'
		color: Brew.colors.white
		color_randomize: [25, 25, 50]
		bgcolor: Brew.colors.water
		bgcolor_randomize: [25, 25, 0]

		description: "a shallow pool of water"
		walkover: "You splash through shallow water"

	CHASM:
		name: 'Chasm'
		code: ':'
		# color: Brew.colors.normal
		color: [220, 220, 220]
		bgcolor: Brew.colors.eggplant
		# bgcolor_randomize: [0, 5, 5]
		blocks_walking: true

		description: "a deep chasm dropping off to the darkness below"
		walkover: "You float above the dark chasm below"

	STAIRS_DOWN:
		name: "Stairs Down"
		code: '>'
		color: Brew.colors.white
		description: "a rough-hewn set of stairs leading deeper"
		walkover: "You step around some stairs leading down into darkness"
		
	STAIRS_UP:
		name: "Stairs Up"
		code: '<'
		color: Brew.colors.white
		desc: "a rough-hewn set of stairs leading back to the surface"
		walkover: "You step around some stairs leading upwards"
		
	DOOR_CLOSED:
		name: "Closed Door"
		code: '+'
		color: Brew.colors.yellow
		bgcolor: Brew.colors.brown

		blocks_vision: true
		blocks_walking: true
		can_open: true
		blocks_flying: true
		can_apply: true

		description: "a sturdy wooden door, shut tight"

	DOOR_OPEN:
		name: "Open Door"
		code: '-'
		color: Brew.colors.yellow
		bgcolor: Brew.colors.brown

		can_apply: true

		description: "a sturdy wooden door, wide open"
		walkover: "You pass through the doorway"
		
	DOOR_BURNT:
		name: "Burnt Door"
		code: '-'
		color: Brew.colors.dark_grey
		# bgcolor: [52, 65, 82]
		bgcolor: Brew.colors.normal

		description: "The charred remains of a wooden door"
		walkover: "You step through the burnt frame"

	ALTAR:
		name: "Altar"
		code: '_'
		color: Brew.colors.white
	# 	can_apply: true
		
	STATUE:
		name: 'Statue'
		code: Brew.unicode.omega
		
		bgcolor: Brew.colors.dark_grey
		bgcolor_randomize: [0, 0, 2]
		color: Brew.colors.steel_blue
		color_randomize: [5, 5, 10]

		blocks_walking: true
		blocks_vision: true
		blocks_flying: true

		description: "an imposing stone statue"

	FLOOR_MOSS:
		name: 'Mossy Stone'
		code: '"'
		
		color: [51, 153, 0]
		color_randomize: [5, 10, 0]
		
		bgcolor: Brew.colors.dark_grey
		bgcolor_randomize: [0, 8, 8]

		description: "moss-covered stone tiles"
		walkover: "Your footsteps barely make any noise on the mossy stone"


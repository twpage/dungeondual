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

	FLOOR:
		name: 'Cavern Floor'
		code: '.'
		color: Brew.colors.normal
		bgcolor: Brew.colors.dark_grey
		bgcolor_randomize: [0, 8, 8]
		show_gore: true

	STONE:
		name: 'Crumbling Stone'
		code: ["'", "`"]
		color: Brew.colors.normal
		bgcolor: Brew.colors.dark_grey
		bgcolor_randomize: [0, 0, 2]
		show_gore: true

	SHALLOW_POOL:
		name: 'Shallow Water'
		code: '~'
		color: Brew.colors.white
		color_randomize: [25, 25, 50]
		bgcolor: Brew.colors.water
		bgcolor_randomize: [25, 25, 0]

	CHASM:
		name: 'Chasm'
		code: ':'
		# color: Brew.colors.normal
		color: [220, 220, 220]
		bgcolor: Brew.colors.eggplant
		# bgcolor_randomize: [0, 5, 5]
		blocks_walking: true

	STAIRS_DOWN:
		name: "Stairs Down"
		code: '>'
		color: Brew.colors.white
		
	STAIRS_UP:
		name: "Stairs Up"
		code: '<'
		color: Brew.colors.white
		
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

	DOOR_OPEN:
		name: "Open Door"
		code: '-'
		color: Brew.colors.yellow
		bgcolor: Brew.colors.brown

		can_apply: true
		
	DOOR_BURNT:
		name: "Burnt Door"
		code: '-'
		color: Brew.colors.dark_grey
		# bgcolor: [52, 65, 82]
		bgcolor: Brew.colors.normal

	# ALTAR:
	# 	name: "Altar"
	# 	code: '_'
	# 	color: Brew.colors.white
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

	FLOOR_MOSS:
		name: 'Mossy Stone'
		code: '"'
		# color: [220, 220, 220]
		# bgcolor: [52, 65, 82]
		bgcolor: [40, 80, 40]
		bgcolor_randomize: [5, 10, 5]
		color: Brew.colors.normal

window.Brew.terrain_def = 
	EMPTY:
		name: 'Empty'
		code: ' '
		color: Brew.colors.normal

	WALL:
		name: 'Wall'
		code: '#'
		# color: [200, 200, 200]
		# color_randomize: [0, 0, 30]
		
		bgcolor: [150, 150, 150]
		bgcolor_randomize: [0, 5, 5]
		color: Brew.colors.dark_grey
		# bgcolor: Brew.colors.normal

		blocks_walking: true
		blocks_vision: true
		blocks_flying: true
		

	FLOOR:
		name: 'Cavern Floor'
		code: '.'
		# color: [220, 220, 220]
		# bgcolor: [52, 65, 82]
		bgcolor: Brew.colors.black
		bgcolor_randomize: [0, 5, 5]
		color: Brew.colors.normal

	STONE:
		name: 'Ancient Stone'
		code: '.'
		# color: [220, 220, 220]
		# bgcolor: [52, 65, 82]
		bgcolor: Brew.colors.dark_grey
		bgcolor_randomize: [0, 5, 5]
		color: Brew.colors.normal

	CHASM:
		name: 'Chasm'
		code: ':'
		# color: Brew.colors.normal
		color: [220, 220, 220]
		bgcolor: Brew.colors.eggplant
		# bgcolor_randomize: [0, 5, 5]
		blocks_walking: true

	ROCKS:
		name: "Crumbling Rock"
		code: [';', ',', '`']
		color: Brew.colors.normal
		
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
		# bgcolor: [150, 150, 150]
		bgcolor: Brew.colors.dark_grey
		blocks_vision: true
		blocks_walking: true
		can_open: true
		blocks_flying: true
		can_apply: true

	DOOR_OPEN:
		name: "Open Door"
		code: '-'
		color: Brew.colors.yellow
		# bgcolor: [52, 65, 82]
		bgcolor: Brew.colors.dark_grey
		can_apply: true
		
	DOOR_BURNT:
		name: "Burnt Door"
		code: '-'
		color: Brew.colors.dark_grey
		# bgcolor: [52, 65, 82]
		bgcolor: Brew.colors.normal

	ALTAR:
		name: "Altar"
		code: '_'
		color: Brew.colors.white
		can_apply: true
		
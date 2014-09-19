dummy = {}
counter = Math.floor(ROT.RNG.getUniform() * 1000000)

idGenerator = () ->
	counter += 1
	return counter
	
class window.LevelGeneratorTester
	constructor: (@my_display) ->
		@levelgen = new Brew.LevelGenerator(@)
		@my_level = null
		
	createAndShow: () ->
		randseed = (new Date()).getTime()
		# randseed = 61903164 # broken one
		# randseed = 609209999 # fine
		@my_level = @levelgen.create(0, Brew.config.level_tiles_width, Brew.config.level_tiles_height,
			{
				ambient_light: [0, 0, 0]
				noItems: true
				levelGen: true
			},
			randseed
		)
		
		@showMyMap()
		
	showMyMap: () ->
		for row_y in [0..@my_display.getOptions().height-1]
			for col_x in [0..@my_display.getOptions().width-1]
				xy = new Coordinate(col_x, row_y)
				t = @my_level.getTerrainAt(xy)
				@my_display.draw(xy.x, xy.y, t.code, ROT.Color.toHex(t.color), ROT.Color.toHex(t.bgcolor))
	
class window.Brew.LevelGenerator
	constructor: (@game) ->
		@id = null
		
	create: (depth, width, height, levelgen_options, level_seed) ->
		ROT.RNG.setSeed(level_seed)
		dungeon_options = getDungeonOptions()
		
		# generate map terrain
		level = new Brew.Level(depth, width, height, levelgen_options)
		[success, rooms, connections] = buildDungeon(level, dungeon_options)
		if not success
			throw "Critical error while building dungeon"

		@makeExciting(level)
		level.calcTerrainNavigation()
		@setupRoomDecoration(level, rooms)

		@growFlora(level, level.getRandomWalkableLocation(), [], 0, 8)

		setupPortals(level)
		setupMonsters(level)

		# reset random seed for items?
		if not levelgen_options?.noItems
			@setupItems(level)

		
		return level

	setupRoomDecoration: (level, rooms) ->
		for own room_id, room of rooms
			put_torch = ROT.RNG.getUniform() < 0.33
			put_statue = ROT.RNG.getUniform() < 0.15
			
			if put_torch
				torch_xy = @findTorchLocation(level, room)
				if torch_xy?
					level.setTerrainAt(torch_xy, Brew.terrainFactory("WALL_TORCH"))
				else
					console.log("couldn't find torch spot")

			if put_statue
				floor_xy = room.getFloors().random()
				level.setTerrainAt(floor_xy, Brew.terrainFactory("STATUE"))

	findTorchLocation: (level, room) ->
		# return a good xy coordinate for a wall torch
		found_spot = false
		tries = 0
		torch_xy = null
		floor_list = room.getFloors()

		while tries < 10
			wall_xy = room.getWalls().random()
			t = level.getTerrainAt(wall_xy)
			if t? and Brew.utils.isTerrain(t, "WALL")
				# check all surrounding open tiles and make sure they are in the same room

				open_tiles = 0
				for neighbor_xy in wall_xy.getAdjacent()
					next_t = level.getTerrainAt(neighbor_xy)
					
					if next_t? and not next_t.blocks_vision
						open_tiles += 1

				if open_tiles == 1
					torch_xy = wall_xy
					break

			tries += 1

		return torch_xy

	growFlora: (level, spawn_xy, visited_list, my_step, max_steps) ->
		# use a flood-fill mechanism to 'grow' dungeon features like fungus, etc

		# stop condition: reached max growth
		if my_step >= max_steps
			return false

		# stop condition: already something here
		if spawn_xy in visited_list
			return false

		# stop condition: current spot is not generic floor tile
		t = level.getTerrainAt(spawn_xy)
		if not t?
			return false

		if not Brew.utils.isTerrain(t, "FLOOR")
			return false

		# create some growth
		level.setTerrainAt(spawn_xy, Brew.terrainFactory("FLOOR_MOSS"))

		# add this point to our visited list
		visited_list.push(spawn_xy)

		# check neighbors
		for neighbor_xy in spawn_xy.getAdjacent()
			@growFlora(level, neighbor_xy, visited_list, my_step + 1, max_steps)

		return true

	makeExciting: (level) ->
		# add chasms using simplex noise

		noise = new ROT.Noise.Simplex(Brew.config.width)

		for x in [0..level.width-1]
			for y in [0..level.height-1]
				val = noise.get(x/20, y/20)
				xy = new Coordinate(x, y)
				t = level.getTerrainAt(xy)

				if val >= 0.75
					# r = ~~(val * 255)
					# g = 0
					# level.setTerrainAt(xy, Brew.terrainFactory("CHASM"))
					level.setTerrainAt(xy, Brew.terrainFactory("STONE"))

				else if val <= -0.75
					# r = 0
					# g = ~~(-val * 255)
					if not Brew.utils.isTerrain(t, "WALL")
						level.setTerrainAt(xy, Brew.terrainFactory("SHALLOW_POOL"))

				# r = ~~(if val > 0 then val*255 else 0)
				# g = ~~(if val < 0 then -val*255 else 0)

		return true

	setupItems: (level) ->
		num_items = Brew.config.items_per_level
		
		# figure out potential monsters for this depth
		potential_items = []
		for own def_id, idef of Brew.item_def
			if not idef.min_depth?
				min_depth = 0
			else
				min_depth = idef.min_depth

			if min_depth > level.depth
				continue

			if min_depth < (level.depth - Brew.config.include_items_depth_lag)
				continue

			potential_items.push(def_id)

		# no weighting for items (yet)
		for i in [1..num_items]
			xy = level.getRandomWalkableLocation()
			def_id = potential_items.random()
			item = Brew.itemFactory(def_id)
			level.setItemAt(xy, item)
			if item.group in [Brew.groups.WEAPON, Brew.groups.ARMOR]
				if ROT.RNG.getUniform() < 0.4
					corpse_xy = @getNearby(level, xy)
					if corpse_xy?
						level.setItemAt(corpse_xy, Brew.itemFactory("ARMY_CORPSE"))
						splat = Brew.utils.createSplatter(corpse_xy, 4)
						for own key, intensity of splat
							level.setFeatureAt(keyToCoord(key), Brew.featureFactory("BLOOD"))

		# extra potions
		extra_flasks = Math.floor(level.depth/2)+1
		for i in [0..extra_flasks]
			xy = level.getRandomWalkableLocation()
			def_id = ["FLASK_FIRE", "FLASK_HEALTH", "FLASK_VIGOR", "FLASK_WEAKNESS", "FLASK_MIGHT", "FLASK_INVISIBLE"].random()
			item = Brew.itemFactory(def_id)
			level.setItemAt(xy, item)

		# usually potion of life
		if ROT.RNG.getUniform() < Brew.config.chance_life_flask
			xy = level.getRandomWalkableLocation()
			level.setItemAt(xy, Brew.itemFactory("FLASK_HEALTH"))

		# usually add a potion of stamina
		if ROT.RNG.getUniform() < Brew.config.chance_vigor_flask
			xy = level.getRandomWalkableLocation()
			level.setItemAt(xy, Brew.itemFactory("FLASK_VIGOR"))



		return true

	getNearby: (level, center_xy) ->
		potentials = []
		for xy in center_xy.getSurrounding()
			if not level.checkValid(xy)
				continue

			t = level.getTerrainAt(xy)
			if t.blocks_walking
				continue

			i = level.getItemAt(xy)
			if i?
				continue

			m = level.getMonsterAt(xy)
			if m?
				continue

			potentials.push(xy)

		if potentials.length == 0
			return null
		else
			return potentials.random()

getDungeonOptions = (user_options) ->
	options = {
		min_room_width: user_options?.min_room_width  ? 8
		max_room_width: user_options?.max_room_width  ?  18
		min_room_height: user_options?.min_room_height  ?  6
		max_room_height: user_options?.max_room_height  ?  12
		min_circle_diameter: user_options?.min_circle_diameter  ?  9
		max_circle_mismatch: user_options?.max_circle_mismatch  ?  3
		prob_circle: user_options?.prob_circle  ? 0.33
		prob_cross: user_options?.prob_cross  ? 1.0
		fill_percentage: user_options?.fill_percentage ? 0.75
		max_tries: user_options?.max_tries ? 500
	}
		
	return options
		
buildDungeon = (level, options) ->
	
	# initialize the entire level to empty tiles
	for x in [0..level.width-1]
		for y in [0..level.height-1]
			level.setTerrainAt(new Coordinate(x, y), Brew.terrainFactory("WALL"))
			
	# get our layout structure
	[floorplan_rooms, connections] = createFloorplan(level, options)
	rooms = {}
	t_start = new Date()
	console.log("START: build dungeon")

	# write terrain for room constructs
	for own room_id, floorplan_room of floorplan_rooms
		
		# sometimes make things other than rectangles??
		room = getRoomFromFloorplan(floorplan_room, options)
		rooms[room_id] = room
		
		for xy in room.getWallsOnly()
			level.setTerrainAt(xy, Brew.terrainFactory("WALL"))
			
		for xy in room.getCorners()
			level.setTerrainAt(xy, Brew.terrainFactory("WALL"))
		
		for xy in room.getFloors()
			level.setTerrainAt(xy, Brew.terrainFactory("FLOOR"))
	
	t_now = new Date()
	console.log("END: build dungeon ", (t_now - t_start))
	
	# design and dig corridors
	digCorridors(level, rooms, connections)

	# put in some doors
	for connection in connections
		door_status = if ROT.RNG.getUniform() < 0.75 then "DOOR_CLOSED" else "DOOR_OPEN"
		level.setTerrainAt(connection.door_xy, Brew.terrainFactory(door_status))
	
	return [true, rooms, connections]
	
getOffsetXY = (side) ->
	offset_xy = null
	if side == "left"
		offset_xy = new Coordinate(-1, 0)
	else if side == "right"
		offset_xy = new Coordinate(1, 0)
	else if side == "top"
		offset_xy = new Coordinate(0, -1)
	else if side == "bottom"
		offset_xy = new Coordinate(0, 1)
	else
		console.log("something terrible happened in getOffsetXY")
		debugger
		
	return offset_xy
	
digCorridors = (level, rooms, connections) ->
	# use Astar to draw some corridors!
	
	t_start = new Date()
	console.log("START: dig corridors ")

	corners = []
	for room in rooms
		corners.merge(room.getCorners())
	corners = (xy.toKey() for xy in corners)
	
	passable_fn = (x, y) =>
		xy = new Coordinate(x, y)
		# t = level.getTerrainAt(xy)
		if xy.toKey() in corners
			return false
		else
			return true
		
	random_points = {}
	path = []
	update_fn = (x, y) ->
		path.push(new Coordinate(x, y))
	
	for connection in connections
		# door -> to_room 
		start_xy = connection.door_xy.add(getOffsetXY(connection.side))
		astar = new ROT.Path.AStar(start_xy.x, start_xy.y, passable_fn, {
			topology: 4}
		)
		
		dest_xy = rooms[connection.room_to].getFloors().random()
			
		path = []
		astar.compute(dest_xy.x, dest_xy.y, update_fn)
		to_path = path[..]

		# door -> from_room
		start_xy = connection.door_xy.add(getOffsetXY(connection.side).multiply(-1))
		astar = new ROT.Path.AStar(start_xy.x, start_xy.y, passable_fn, {
			topology: 4}
		)

		dest_xy = rooms[connection.room_from].getFloors().random()
			
		path = []
		astar.compute(dest_xy.x, dest_xy.y, update_fn)
		from_path = path[..]
		
		# dig out corridors
		for path_xy in from_path
			level.setTerrainAt(path_xy, Brew.terrainFactory("FLOOR")) # , {color: Brew.colors.pink }))
			
		for path_xy in to_path
			level.setTerrainAt(path_xy, Brew.terrainFactory("FLOOR")) # , {color: Brew.colors.light_blue }))
			
	t_now = new Date()
	console.log("END: dig corridors ", (t_now - t_start))

	return true

getRoomFromFloorplan = (floorplan_room, options) ->
	room = null
	
	# can we make a circle?
	min_diameter = Math.min(floorplan_room.width, floorplan_room.height)
	mismatch = Math.abs(floorplan_room.width - floorplan_room.height)
	is_circle_possible  = min_diameter >= options.min_circle_diameter and mismatch <= options.max_circle_mismatch
	
	if is_circle_possible and ROT.RNG.getUniform() < options.prob_circle
		room = new CircleRoom(floorplan_room.left, floorplan_room.top, min_diameter, min_diameter)
	else
		# make a non-circle room
		if ROT.RNG.getUniform() < options.prob_cross
			room = createCrossRoom(floorplan_room, options)
		else
			room = floorplan_room
	
	return room

createFloorplan = (level, options) ->
	# return a list of rectangular rooms all slapped together at random adjacent door locations
	
	placed_rooms = {}
	
	is_valid_fn = (r) =>
		return r.left >= 0 and r.top >= 0 and r.right < level.width and r.bottom < level.height
			
	# place first room (guaranteed)
	first_room = createRectangleRoom(options)
	first_room.randomizeCorner(level.width, level.height)
	placed_rooms[first_room.id] = first_room
	connections = []
	
	tries = 0
	t_start = new Date()
	console.log("START: floorplan generation")
	level_area = level.width * level.height
	room_area_percent = 0
	
	while room_area_percent < options.fill_percentage and tries < options.max_tries
		tries += 1
		room_area = ((r.width * r.height) for own id, r of placed_rooms).reduce (t, s) -> t + s
		room_area_percent = room_area / level_area
		
		# pick a random room to spawn from
		base_room = (room for own id, room of placed_rooms).random()
		# base_room = placed_rooms.random()
		
		# pick a random wall
		wall_xy = base_room.getWallsOnly().random()
		
		# make a new random room
		new_room = createRectangleRoom(options)
		doorside = null
		
		# pick a random spot next to the base room
		if wall_xy.x == base_room.left # new room on left side
			new_x = base_room.left - new_room.width + 1
			min_y = wall_xy.y - new_room.height + 2
			max_y = wall_xy.y - 0
			new_y = Math.floor(ROT.RNG.getUniform()*(max_y - min_y)) + min_y
			doorside = "left"
			
		else if wall_xy.x == base_room.right # new room on right side
			new_x = base_room.right 
			min_y = wall_xy.y - new_room.height + 2
			max_y = wall_xy.y - 0
			new_y = Math.floor(ROT.RNG.getUniform()*(max_y - min_y)) + min_y
			doorside = "right"
			
		else if wall_xy.y == base_room.top # new room on top
			new_y = base_room.top - new_room.height + 1
			min_x = wall_xy.x - new_room.width + 2
			max_x = wall_xy.x - 0
			new_x = Math.floor(ROT.RNG.getUniform()*(max_x - min_x)) + min_x
			doorside = "top"
			
		else if wall_xy.y == base_room.bottom # new room below
			new_y = base_room.bottom
			min_x = wall_xy.x - new_room.width + 2
			max_x = wall_xy.x - 0
			new_x = Math.floor(ROT.RNG.getUniform()*(max_x - min_x)) + min_x
			doorside = "bottom"
			
		else
			# wtf?
			console.log("wtf?")
			console.log(wall_xy)
			console.log(new_room)
			break
		
		# see if we can place the new room
		new_room.resetCornerAt(new_x, new_y)
		if not is_valid_fn(new_room)
			# console.log("rejected, not inside valid area")
			continue
			
		overlap = false
		# console.log("checking vs " + placed_rooms.length + " placed rooms")
		for own id, existing_room of placed_rooms
			if existing_room.checkOverlapExcludingWalls(new_room)
				overlap = true
				break
		
		if overlap
			# console.log("rejected, overlaps existing room")
			continue
				
		# otherwise we're good
		placed_rooms[new_room.id] = new_room
		connections.push(new Connection(base_room.id, new_room.id, wall_xy, doorside))
	
	t_now = new Date()
	console.log("END: floorplan generation in #{tries} tries ", (t_now - t_start))
	return [placed_rooms, connections]

setupMonsters = (level) ->
	num_monsters = Brew.config.monsters_per_level
	
	# figure out potential monsters for this depth
	# where level depth is AT LEAST min_depth, 
	# but not greater than 2
	potential_monsters = []
	for own def_id, mdef of Brew.monster_def
		if not mdef.min_depth?
			continue

		if mdef.min_depth > level.depth
			continue

		if mdef.min_depth < (level.depth - Brew.config.include_monsters_depth_lag)
			continue

		potential_monsters.push(def_id)

	# add up all monster raritys by weight
	weighted = {}
	for def_id in potential_monsters
		weighted[def_id] = Brew.monster_def[def_id].rarity

	total = (wgt for own d, wgt of weighted).reduce (t, s) -> t + s

	last_wgt = 0
	for own def_id, wgt of weighted
		new_wgt = last_wgt + (wgt / total)
		weighted[def_id] = new_wgt
		last_wgt = new_wgt
	
	# add monsters weighterly
	# bject {CLOCK_SPIDER: 0.4, GIANT_SPIDER: 0.6000000000000001, KOBOLD: 1} 
	# ject {CLOCK_SPIDER: 0, GIANT_SPIDER: 0.4, KOBOLD: 0.6000000000000001} 
	for i in [1..num_monsters]
		tries = 0
		xy = null
		while tries < 10
			xy = level.getRandomWalkableLocation()
			dist_to_start = Brew.utils.dist2d(level.start_xy, xy)

			if dist_to_start < 10
				xy = null
				tries += 1
			else
				break

		if not xy
			continue

		u = ROT.RNG.getUniform()
		for own def_id, wgt of weighted
			if u < wgt
				monster = Brew.monsterFactory(def_id, {status: Brew.monster_status.WANDER})
				# console.log("added monster #{def_id}")
				level.setMonsterAt(xy, monster)
				break

	## add time master at final depth
	if level.depth == Brew.config.max_depth
		xy = level.getRandomWalkableLocation()
		level.setMonsterAt(xy, Brew.monsterFactory("TIME_MASTER", {status: Brew.monster_status.WANDER}))

	## add tutorials at first depth
	if level.depth == 0
		for i in [0..Brew.tutorial_texts.length-1]
			xy = level.getRandomWalkableLocation()
			level.setItemAt(xy, Brew.itemFactory("INFO_POINT", {name: "Help", description: Brew.tutorial_texts[i]}))

	return true
	
setupPortals = (level) ->
	# entrance and exit
	level.start_xy = level.getRandomWalkableLocation()

	if level.depth > 0
		level.setTerrainAt(level.start_xy, Brew.terrainFactory("STAIRS_UP"))
		
	while true
		level.exit_xy = level.getRandomWalkableLocation()
		if not level.exit_xy.compare(level.start_xy)
			break
			
	level.setTerrainAt(level.exit_xy, Brew.terrainFactory("STAIRS_DOWN"))
	level.setUnlinkedPortalAt(level.exit_xy)
	
	return true

# RANDOM ROOM GENERATOR FUNCTIONS
# ----------------------------------------
createRectangleRoom = (options) ->
	min_width = options.min_room_width
	max_width = options.max_room_width
	min_height = options.min_room_height
	max_height = options.max_room_height
	
	rand_width = Math.floor(ROT.RNG.getUniform()*(max_width-min_width)) + min_width
	rand_height = Math.floor(ROT.RNG.getUniform()*(max_height-min_height)) + min_height
	r = new RectangleRoom(0, 0, rand_width, rand_height)
	
	return r
	
# ----------------------------------------
createCrossRoom = (area, options) ->
	# creates a random cross room within given rectangular room boundaries
	min_width = options.min_room_width
	min_height = options.min_room_height
	
	small_width = Math.floor(ROT.RNG.getUniform()*(area.width - min_width)) + min_width
	small_height = Math.floor(ROT.RNG.getUniform()*(area.height - min_height)) + min_height

	random_x = Math.floor(ROT.RNG.getUniform()*(area.width - small_width))
	random_y = Math.floor(ROT.RNG.getUniform()*(area.height - small_height))
	
	# room_wide = new RectangleRoom(0, random_y, area.width, small_height)
	# room_tall = new RectangleRoom(random_x, 0, small_width, area.height)
	room_wide = new RectangleRoom(area.left, area.top + random_y, area.width, small_height)
	room_tall = new RectangleRoom(area.left + random_x, area.top, small_width, area.height)
	
	cross = new CrossRoom(area.left, area.top, area.width, area.height)
	cross.room_wide = room_wide
	cross.room_tall = room_tall
	
	return cross
	
# ROOM CLASSES
class Connection
	constructor: (@room_from, @room_to, @door_xy, @side) ->
	
class Room
	constructor: (@left, @top, @width, @height) ->
		@id = idGenerator()
		@right = @left + @width - 1
		@bottom = @top + @height - 1
		
	getFloors: () ->
		throw new Error("does not implement getFloors")
	getWalls: () ->
		throw new Error("does not implement getWalls")
	getCorners: () ->
		throw new Error("does not implement getCorners")
	isCorner: (xy) ->
		throw new Error("does not implement isCorner")
	getWallsOnly: () ->
		throw new Error("does not implement getWallsOnly")
		
# ----------------------------------------
class RectangleRoom extends Room
	checkOverlap: (room) ->
		no_overlap = @left > room.right or @right < room.left or @top > room.bottom or @bottom < room.top
		return not no_overlap
		
	checkOverlapExcludingWalls: (room) ->
		no_overlap = @left >= room.right or @right <= room.left or @top >= room.bottom or @bottom <= room.top
		return not no_overlap

	isInside: (xy) ->
		return xy.x > @left and xy.x < @right and xy.y > @top and xy.y < @bottom
		
	getFloors: () ->
		floors = []
		for x in [@left+1..@right-1]
			for y in [@top+1..@bottom-1]
				floors.push(new Coordinate(x, y))
		
		return floors
		
	getWalls: () ->
		walls = []
		for x in [@left..@right]
			walls.push(new Coordinate(x, @top))
			walls.push(new Coordinate(x, @bottom))
		
		for y in [@top+1..@bottom-1]
			walls.push(new Coordinate(@left, y))
			walls.push(new Coordinate(@right, y))
		
		return walls
		
	getCorners: () ->
		corners = [
			new Coordinate(@left, @top),
			new Coordinate(@right, @top),
			new Coordinate(@left, @bottom),
			new Coordinate(@right, @bottom)
		]
		return corners
		
	isCorner: (xy) ->
		return @getCorners().some( (c) => c.compare(xy) )
		
	getWallsOnly: () ->
		return (xy for xy in @getWalls() when not @isCorner(xy))
		
	resetCornerAt: (left, top) ->
		@top = top
		@left = left
		@bottom = @top + @height - 1
		@right = @left + @width - 1
		return true
		
	randomizeCorner: (area_width, area_height) ->
		new_left = Math.floor(ROT.RNG.getUniform()*(area_width - @width))
		new_top = Math.floor(ROT.RNG.getUniform()*(area_height - @height))
		@resetCornerAt(new_left, new_top)

# ----------------------------------------
class CircleRoom extends RectangleRoom
	@floors = []
	
	getWallsOnly: () ->
		return @getWalls()
		
	getCorners: () ->
		return []
		
	getWalls: () ->
		if @width != @height
			debugger
		
		walls = []
		floors = []
		
		radius = (@width - 1) / 2.0
		cx = @left + radius
		cy = @top + radius
		
		for x in [@left..@right]
			for y in [@top..@bottom]
				dist = Brew.utils.dist2d_xy(cx, cy, x, y)
				if dist >= radius
					walls.push(new Coordinate(x, y))
				else
					floors.push(new Coordinate(x, y))
					
		@floors = floors
		return walls
	
	getFloors: () ->
		if not @floors?
			walls = @getWalls()
		return @floors

# ----------------------------------------
class CrossRoom extends Room
	@room_tall: null
	@room_wide: null
	
	getWallsOnly: () ->
		return @getWalls()
	
	getCorners: () ->
		corners = []
		corners.merge(@room_wide.getCorners())
		corners.merge(@room_tall.getCorners())
		return corners
		
	getFloors: () ->
		floors = []
		floors.merge(@room_wide.getFloors())
				
		for xy in @room_tall.getFloors() when xy not in floors
			# if not @room_wide.isInside(xy)
			floors.push(xy)
			
		return floors
		
	getWalls: () ->
		walls = []
		wide_walls = @room_wide.getWalls()
		tall_walls = @room_tall.getWalls()
		
		for xy in wide_walls
			if not @room_tall.isInside(xy)
				walls.push(xy)
				
		for xy in tall_walls
			if not @room_wide.isInside(xy)
				walls.push(xy)
		
		# walls.merge(@room_tall.getWalls())

		return walls

# ----------------------------------------
class CorridorsRoom extends Room
	@floors = []
	
	getFloors: () ->
		# find center, that's the only floor I guess?
		cx = @left + Math.floor(@width / 2)
		cy = @top + Math.floor(@height / 2)
		return [new Coordinate(cx, cy)]
	
	getWalls: () ->
		return []
	
	getCorners: () ->
		return []
	
	isCorner: (xy) ->
		return false
		
	getWallsOnly: () ->
		return @getWalls()


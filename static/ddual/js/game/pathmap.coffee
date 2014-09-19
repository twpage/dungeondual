# DIJKSTRA PATH MAPS

# private functions
initPathMap = (dungeon) ->
	# returns an [xyKey] map using the current level's width x height, filled with MAX_INT
	pathmap = {}
	
	# for x in [-1..dungeon.width-1]
		# for y in [-1..dungeon.height-1]
	for x in [-1..dungeon.width]
		for y in [-1..dungeon.height]
			pathmap[keyFromXY(x, y)] = MAX_INT
	
	return pathmap

solvePathMap = (pathmap, passable_lst) ->
	made_changes = true
	passes = 1
	while made_changes
		made_changes = false
		
		for grid_key in passable_lst
			neighbor_key_lst = getAdjacentKeys(grid_key)
			# neighbor_lst = keyToCoord(grid_key).getAdjacent() 
			# neighbor_lst = keyToCoord(grid_key).getSurrounding() 
			neighbor_val = MAX_INT
			
			# for neighbor_xy in neighbor_lst
				# neighbor_val = Math.min(neighbor_val, pathmap[neighbor_xy.toKey()])
			
			for neighbor_key in neighbor_key_lst
				neighbor_val = Math.min(neighbor_val, pathmap[neighbor_key])
				
			if ((pathmap[grid_key] - neighbor_val) >= 2)
				pathmap[grid_key] = neighbor_val + 1
				made_changes = true
				
		passes += 1
			
	max_value = null
	min_value = null
	for own key, value of pathmap
		if not value or value == MAX_INT
			continue
		max_value = if not max_value then value else Math.max(max_value, value)
		min_value = if not min_value then value else Math.min(min_value, value)
		
	pathmap.max_value = max_value
	pathmap.min_value = min_value
	
	# console.log("solved with " + passes + " passes")
	return pathmap

# exposed functions
window.Brew.PathMap = 
	createGenericMapToPlayer: (dungeon, player_xy, max_distance, options) ->
		# returns an [xyKey] keyed object with (int) values representing a dijkstra map
		options ?= {}
		use_flying = options.use_flying ? false

		pathmap = initPathMap(dungeon)
		
		# iterate through our passable locations
		if use_flying
			avail_key_list = dungeon.navigation.fly.key
		else
			avail_key_list = dungeon.navigation.walk.key
		
		passable_lst = (w for w in avail_key_list[..] when Brew.utils.dist2d(player_xy, keyToCoord(w)) < max_distance)

		# set goal points and
		# remove some passable terrain depending on if a monster is on it
		for own key, mob of dungeon.monsters
			
			if mob.group == "player"
				pathmap[key] = 0 # the target is our goal point (0)
				player_xy = keyToCoord(key)
				
			# remove only immobile monsters
			else if mob.hasFlag(Brew.flags.is_immobile)
				# console.log("pathmap for #{focus_monster.id}, removing #{mob.id}")
				passable_lst.remove(Number(key))
			
		return solvePathMap(pathmap, passable_lst)

	createMapToPlayer: (dungeon, player_xy, focus_monster, max_distance) ->
		# returns an [xyKey] keyed object with (int) values representing a dijkstra map
		
		pathmap = initPathMap(dungeon)
		
		# iterate through our passable locations
		if focus_monster.hasFlag(Brew.flags.is_flying)
			avail_key_list = dungeon.navigation.fly.key
		else
			avail_key_list = dungeon.navigation.walk.key
		
		passable_lst = (w for w in avail_key_list[..] when Brew.utils.dist2d(player_xy, keyToCoord(w)) < max_distance)

		# set goal points and
		# remove some passable terrain depending on if a monster is on it
		for own key, mob of dungeon.monsters
			
			if mob.group == "player"
				pathmap[key] = 0 # the target is our goal point (0)
				player_xy = keyToCoord(key)
				
			else if not Brew.utils.compareThing(mob, focus_monster)
				# remove monsters other than our focus mob
				# console.log("pathmap for #{focus_monster.id}, removing #{mob.id}")
				passable_lst.remove(Number(key))
			
		return solvePathMap(pathmap, passable_lst)
	
	createMapFromPlayer: (dungeon, player_xy, focus_monster, to_map, max_distance) ->
		# converts a 'to player' map to a 'escape from player' map
		
		escape_factor = -1.2
		from_map = {} # dont actually need this in coffee script
		
		# iterate through our passable locations
		if focus_monster.hasFlag(Brew.flags.is_flying)
			avail_key_list = dungeon.navigation.fly.key
		else
			avail_key_list = dungeon.navigation.walk.key
		
		passable_lst = (w for w in avail_key_list[..] when Brew.utils.dist2d(player_xy, keyToCoord(w)) < max_distance)

		# invert the to-map
		for own map_key, map_value of to_map
			from_map[map_key] = if map_value == MAX_INT then map_value else Math.ceil((map_value * escape_factor))
	
		# set goal points and
		# remove some passable terrain depending on if a monster is on it
		for own key, mob of dungeon.monsters
			if mob.group == "player"
				from_map[key] = MAX_INT
			else if not Brew.utils.compareThing(mob, focus_monster)
				# remove monsters other than our focus mob
				passable_lst.remove(Number(key))

		from_map = solvePathMap(from_map, passable_lst)
		
		return from_map
		
	getDownhillNeighbor: (pathmap, location_xy) ->
		# 'roll downhill' on a dijkstra map and return the location of the lowest value
		# lowest_value = MAX_INT
		lowest_xy = location_xy
		lowest_value = pathmap[location_xy.toKey()]
		
		for neighbor_xy in location_xy.getSurrounding()
		# for neighbor_xy in location_xy.getAdjacent()
			temp_value = pathmap[neighbor_xy.toKey()]
			if temp_value < lowest_value
				lowest_value = temp_value
				lowest_xy = neighbor_xy
				
		return {
			xy: lowest_xy
			value: lowest_value
		}

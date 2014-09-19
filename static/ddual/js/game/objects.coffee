counter = Math.floor(ROT.RNG.getUniform() * 1000000)

idGenerator = () ->
	counter += 1
	return counter

class window.Brew.Thing
	constructor: (@objtype) ->
		@id = idGenerator()
		@code = null
		@color = null
		@bgcolor = null
		@coordinates = {x: null, y: null}
		@flags = []
		@flagcounters = {}
		@stats = {}

	compare: (other_thing) ->
		return id == other_thing.id
		
	getSpeed: ->
		return 100

	getLocation: ->
		coordinates
		
	setLocation: (xy) ->
		@coordinates = xy
		true
		
	getFlags: () ->
		return @flags
		
	hasFlag: (flag) ->
		return flag in @flags
		
	setFlag: (flag) ->
		if not @hasFlag(flag)
			@flags.push(flag)
		true
		
	removeFlag: (flag) ->
		if @hasFlag(flag)
			@flags.remove(flag)
			return true
		else
			return false
		
	toggleFlag: (flag) ->
		if @hasFlag(flag)
			@removeFlag(flag)
		else
			@setFlag(flag)
			
	# flags with timers
	getFlagCounters: () -> 
		return (f for own f, v of @flagcounters)

	setFlagCounter: (flag, effect_turns, stop_turn) ->
		@setFlag(flag)
		@flagcounters[flag] = [effect_turns, stop_turn]
		true

	removeFlagCounter: (flag) ->
		@removeFlag(flag)
		delete @flagcounters[flag]
		true

	getFlagCount: (flag) ->
		return @flagcounters[flag][1]
	
	getFlagCountDuration: (flag) ->
		return @flagcounters[flag][0]

	# stat
	createStat: (stat_name, init_value) ->
		@stats[stat_name] = new Brew.Stat(stat_name, init_value)
		true
		
	getStat: (stat_name) -> @stats[stat_name]

	# JSON
	toObject: () ->
		# convert bare minimum of thing facts to json
		return {
			"objtype": @objtype
			"def_id": @def_id
			"id": @id
			"code": @code
			"color": @color
			"bgcolor": @bgcolor
			"name": @name
			"group": @group
			"coordinates": @coordinates.toObject()
			"stats": @stats
		}

class window.Brew.Terrain extends Brew.Thing
	constructor: (terrain_info) ->
		super "terrain"

		# handle special attributes
		@group = terrain_info.group ? terrain_info.name
		@bgcolor = terrain_info.bgcolor ? Brew.colors.black
		@blocks_vision = terrain_info.blocks_vision ? false
		@blocks_walking = terrain_info.blocks_walking ? false
		@blocks_flying = terrain_info.blocks_flying ? false
		@code = if typeIsArray(terrain_info.code) then terrain_info.code[Math.floor(ROT.RNG.getUniform()*terrain_info.code.length)] else terrain_info.code
		@show_gore = terrain_info.show_gore ? false

		# handle everything else via direct assignment
		for own param, value of terrain_info
			if @[param]?
				continue
			this[param] = value

class window.Brew.Feature extends Brew.Thing
	constructor: (feature_info) ->
		super "feature"
		
		@group = feature_info.group ? feature_info.name
		@code = @generateCode(feature_info)
		@color = feature_info.color ? null
		@bgcolor = feature_info.bgcolor ? [0, 0, 0]
		
		# @alive = feature_info.alive ? false
		@intensity = feature_info.intensity ? 0
		
		# handle everything else via direct assignment
		for own param, value of feature_info
			if @[param]?
				continue
			this[param] = value
			
	generateCode: (feature_info) ->
		if not feature_info.code?
			return null

		return if typeIsArray(feature_info.code) then feature_info.code[Math.floor(ROT.RNG.getUniform()*feature_info.code.length)] else feature_info.code
		
	getColor: () ->
		# scales color based on intensity
		return (Math.floor(@color[i] * @intensity) for i in [0, 1, 2])

	getBackgroundColor: () ->
		# scales background color based on intensity
		return (Math.floor(@bgcolor[i] * @intensity) for i in [0, 1, 2])

class window.Brew.Item extends Brew.Thing
	constructor: (item_info) ->
		super "item"

		# handle special attributes
		@group = item_info.group ? item_info.name
		@code = Brew.group[@group].code
		@bgcolor = item_info.bgcolor ? [0, 0, 0]
		@damage = item_info.damage ? 0

		# handle everything else via direct assignment
		for own param, value of item_info
			if @[param]?
				continue
			this[param] = value

		@flags = item_info.flags ? @flags


inventory_key_list = (String.fromCharCode(x) for x in [65..81])

class window.Brew.Inventory
	# contains a bunch of items
	constructor: (max_items) ->
		@items = {}
		@max_items = max_items ? 16
		if @max_items > inventory_key_list.length
			throw "not enough inventory keys"
		@equipped = {}
		
	getItems: () ->
		return (item for own key, item of @items)
			
	getKeys: () ->
		return (key for own key, item of @items)

	addItem: (new_item) ->
		if @getItems().length == @max_items
			return null
		else
			next_key = @getNextKey()
			new_item.inv_key = next_key
			new_item.inv_key_lower = String.fromCharCode(next_key.charCodeAt(0)+32)
			@items[next_key] = new_item
		return next_key
		
	removeItemByKey: (inv_key) ->
		item = @items[inv_key]
		item.inv_key = null
		item.inv_key_lower = null
		item.equip = null
		delete @items[inv_key]
		true
	
	getNextKey: () ->
		existing_keys = @getKeys()
		
		for key in inventory_key_list
			if key not in existing_keys
				return key
				
		throw "unable to generate new inventory key"
		return null
		
	getItem: (inv_key) ->
		@items[inv_key]

	hasItem: (item) ->
		return item.id in (i.id for i in @getItems())
		
	equipItem: (item, equip_slot) ->
		if not item.id in (i.id for i in @getItems)
			throw "equipping item not in this inventory!"
			
		if not equip_slot of Brew.equip_slot
			throw "invalid equip slot " + equip_slot
			
		item.equip = equip_slot
		true
		
	getEquipped: (equip_slot) ->
		p = (item for own key, item of @items when item?.equip == equip_slot)
		if p.length == 0
			return null
		else if p.length > 1
			throw "more than 1 item for given equip slot " + equip_slot
		else
			return p[0]
			
	unequipItem: (item) ->
		if not item.equip?
			throw "item was not equipped"
		item.equip = null
		true

class window.Brew.Horde
	constructor: (@monsters) ->
		@id = idGenerator()
		
	updateAll: (last_player_xy) ->
		for m in @monsters
			m.last_player_xy = last_player_xy
		true
	
	add: (mob) ->
		mob.horde = @
		@monsters.push(mob)
		true
		
	hasKnowledgeOf: (something) ->
		for m in @monsters
			if m.hasKnowledgeOf(something)
				return true
				
		return false

###
stats - 
###
class window.Brew.Stat
	constructor: (@name, value) ->
		@current = value
		@max = value
		
	getCurrent: -> @current
	getMax: -> @max
	isZero: -> @current <= 0
	isMax: -> @current == @max
	
	addTo: (amount) ->
		@current = Math.min(@max, @current + amount)
		true
		
	deduct: (amount) ->
		@current = Math.max(0, @current - amount)
		true
	
	setTo: (amount) ->
		@current = amount
		true

	addToMax: (amount) ->
		@current += 1
		@max += 1
		true

	reset: () ->
		@current = @max
		true

	deductOverflow: (amount) ->
		# returns any amount below zero
		if amount <= @current
			@deduct(amount)
			return 0
		else
			overflow = amount - @current
			@current = 0
			return overflow

class window.Brew.Monster extends Brew.Thing
	constructor: (monster_info) ->
		super "monster"
		@fov = {} # coordinates this monster can see
		@knowledge = []
		@memory = {}
		@pathmaps = {}
		@sight_radius = monster_info.sight_radius ? 9
		@inventory = new Brew.Inventory()
		@status = monster_info.status ? Brew.monster_status.SLEEP
		@rank = monster_info.rank ? 0
		@damage = monster_info.damage ? 1
		@horde = monster_info.horde ? null
		@attack_range = monster_info.attack_range ? 1
		@agent = monster_info.agent ? false
		@abilities = []
		@active_ability = null

		# handle special attributes
		@group = monster_info.group ? monster_info.name
		@bgcolor = monster_info.bgcolor ? [0, 0, 0]
		
		# handle everything else via direct assignment
		for own param, value of monster_info
			if @[param]?
				continue
			this[param] = value
			
		@flags = monster_info.flags ? @flags
			
	# abilities
	getAbilities: () ->
		return @abilities
		
	hasAbility: (ability) ->
		return ability in @abilities
		
	addAbility: (ability) ->
		if not @hasAbility(ability)
			@abilities.push(ability)
		true
		
	removeAbility: (ability) ->
		if @hasAbility(ability)
			@abilities.remove(ability)
			return true
		else
			return false

	# combat

	getAttackRange: () ->
		return @attack_range

	getAttackDamage: (is_melee) ->
		return @damage ? 0

	# memory
	setMemoryAt: (level_id, xy, something) -> 
		if level_id not of @memory
			@memory[level_id] = {}
		@memory[level_id][xy.toKey()] = something
		true
		
	getMemoryAt: (level_id, xy) ->
		return if @memory[level_id]? then (@memory[level_id][xy.toKey()] ? null) else null
		
	# FIELD OF VIEW
	canView: (xy) ->
		if @hasFlag(Brew.flags.see_all)
			return true
		else
			return xy.toKey() of @fov
		
	clearFov: ->
		@fov = {}
		true
	
	clearKnowledge: ->
		@knowledge = []
		true
		
	setFovAt: (level, xy) ->
		@fov[xy.toKey()] = true
		@updateKnowledgeAt(level, xy)
		true
	
	updateKnowledgeAt: (level, xy) ->
		if xy.compare(@coordinates)
			return true
		item = level.getItemAt(xy)
		if item?
			@knowledge.push(item.id)
			
		mob = level.getMonsterAt(xy) 
		if mob? and not mob.hasFlag(Brew.flags.invisible) # what about can see invisible?
			if @group != "player" and mob.group == "player"
				@last_player_xy = xy
				if @horde?
					@horde.updateAll(xy)
			@knowledge.push(mob.id)
			
		true
		
	hasKnowledgeOf: (thing) ->
		# return true if thing ID's in my knowledge 
		return thing.id in @knowledge
		
	updateFov: (ye_level) ->
		@clearFov()
		@clearKnowledge()
		my_x = @coordinates.x
		my_y = @coordinates.y

		fn_allow_vision = (x, y) -> 
			# can never see outside the level
			if x < 0 or x >= ye_level.width or y < 0 or y >= ye_level.height
				return false
			# can always see where you are standing
			else if x == my_x and y == my_y
				return true
			else
				return not ye_level.checkBlocksVision(new Coordinate(x, y))
			
		fn_update_fov = (x, y, r, visibility) =>
			# also update level for lightcasting
			# ye_level.setLightAt(new Coordinate(x, y), 1)
			@setFovAt(ye_level, new Coordinate(x, y))
			return true
			
		# rot_fov = new ROT.FOV.DiscreteShadowcasting(fn_allow_vision)
		rot_fov = new ROT.FOV.PreciseShadowcasting(fn_allow_vision)
		rot_fov.compute(@coordinates.x, @coordinates.y, @sight_radius, fn_update_fov)
		
		# add monsters telepathically
		# if @group == "player"
			# for own key, monster of ye_level.monsters
				# monster_xy = keyToCoord(key)
				# if monster.group == "player"
					# continue
			
				# else # if monster.objtype == "monster"
					# @setFovAt(ye_level, monster_xy)
					# for xy in monster_xy.getSurrounding()
						# @setFovAt(ye_level, xy)
					
		return true

class window.Brew.Level
	constructor: (@depth, @width, @height, options) ->
		@id = idGenerator()
		@terrain = {}
		@features = {}
		@overheads = {}
		@monsters = {}
		@items = {}
		@light = {}
		@portals = {}
		@agents = {}

		@ambient_light = options?.ambient_light ? [130, 130, 130]
		# @walkable_xy_list = []
		# @walkable_key_list = []
		@navigation = {}
	
	updateLightMap: () ->
		@light = {} # clear old info
		lightsources = []
		
		# add any monsters with light sources
		for own key, monster of @monsters
			if monster.light_source?
				lightsources.push({
					center: monster.coordinates,
					color: monster.light_source
					})
			
		# overhead with lightsources?
		for own key, overhead of @overheads
			if overhead.light_source?
				xy = keyToCoord(key)
				lightsources.push({
					center: xy,
					color: overhead.light_source
					})
					
		# terrain light sources
		for own key, t of @terrain
			if t.light_source?
				xy = keyToCoord(key)
				
				lightsources.push({
					center: xy,
					# radius: 3,
					color: t.light_source
					})
					
		fn_allow_vision = (x, y) => 
			if x < 0 or x >= @width or y < 0 or y >= @height
				return false
			else
				return not @checkBlocksLight(new Coordinate(x, y))
			
		fn_update_light = (x, y, color) =>
			# also update level for lightcasting
			# ye_level.setLightAt(new Coordinate(x, y), 1)
			@setLightAt(new Coordinate(x, y), color)
			
		fn_reflectivity = (x, y) => 
			return 0
			# if x < 0 or x >= @width or y < 0 or y >= @height
				# return 0
			# else
				# return if @checkBlocksVision(new Coordinate(x, y)) then 0 else 0.3
		light_range = Math.floor(Math.min(@width, @height) / 2)
		rot_fov = new ROT.FOV.PreciseShadowcasting(fn_allow_vision)
		lighting = new ROT.Lighting(fn_reflectivity, {range: light_range, passes:2})
		lighting.setFOV(rot_fov)
		for light in lightsources
			lighting.setLight(light.center.x, light.center.y, light.color)
			
		lighting.compute(fn_update_light)
		
		true
			
	checkValid: (xy) ->
		is_valid = xy.x >= 0 and xy.x < @width and xy.y >= 0 and xy.y < @height
		return is_valid
		
	checkBlocksVision: (xy) ->
		t = @getTerrainAt(xy)
		if not t?
			debugger

		return t.blocks_vision
	
	checkBlocksLight: (xy) ->
		t = @getTerrainAt(xy)
		if not t?
			debugger

		if t.light_source?
			return false
		else
			return t.blocks_vision

	# terrain
	setTerrainAt: (xy, terrain) ->
		key = xy.toKey()
		
		existing_terrain = @terrain[key]
		if existing_terrain?
			@calcTerrainNavigation()
				
		terrain.coordinates = xy
		@terrain[key] = terrain
		
		true
		
	getTerrain: () -> @terrain

	getTerrainAt: (xy) ->
		return @terrain[xy.toKey()]

	calcTerrainNavigation: () ->
		# keep track of which terrain is navigatable by different means

		# initialize terrain navigation 
		@navigation =  
			walk: 
				xy: []
				key: []
			fly: 
				xy: []
				key: []
			# ignore_radiation: []

		# for own key, terrain of @terrain ## firefox and chrome handle object element iter differently
		for x in [0..@width-1]
			for y in [0..@height-1]
				key = keyFromXY(x, y)
				terrain = @terrain[key]

				canWalk = (not terrain.blocks_walking) or (terrain.blocks_walking and terrain.can_open? and terrain.can_open)
				canFly = canWalk or (not terrain.blocks_flying)

				if canWalk
					@navigation.walk.xy.push(keyToCoord(key))
					@navigation.walk.key.push(Number(key))

				if canFly
					@navigation.fly.xy.push(keyToCoord(key))
					@navigation.fly.key.push(Number(key))

		true
	
	getRandomWalkableLocation: () ->
		# return a coordinate of a valid walkable terrain in the dungeon
		# guaranteed not to have a monster on it
		tries = 0
		while tries < 50
			index = Math.floor(ROT.RNG.getUniform()*@navigation.walk.xy.length)
			xy = @navigation.walk.xy[index]
			# console.log("start ", @start_xy)
			# console.log("exit ", @exit_xy)
			# if not (@getMonsterAt(xy)? or @getTerrainAt(xy).blocks_vision) or xy.compare(@start_xy) or xy.compare(@exit_xy)
			# 	return xy
			if @getMonsterAt(xy)?
				tries += 1
				continue
			
			if @getTerrainAt(xy).blocks_vision
				tries += 1
				continue

			if @start_xy? and xy.compare(@start_xy)
				tries += 1
				continue

			if @exit_xy? and xy.compare(@exit_xy)
				tries += 1
				continue
				
			return xy

		console.error("getRandomWalkableLocation failed ", tries)
		return null
	
	getRandomWalkableLocationNear: (center_xy, distance) ->
		# return a coordinate of a valid walkable terrain in the dungeon
		# guaranteed not to have a monster on it

		right = center_xy.x - Math.floor(distance / 2)
		top = center_xy.y - Math.floor(distance / 2)
		left = center_xy.x + Math.floor(distance / 2)
		bottom = center_xy.y + Math.floor(distance / 2)

		possible_lst = []
		for x in [right..left]
			for y in [top..bottom]
				xy = new Coordinate(x, y)
				if xy.compare(center_xy)
					continue

				t = @getTerrainAt(xy)
				if not t?
					continue
				if t.blocks_walking
					continue

				i = @getItemAt(xy)
				if i?
					continue
				
				m = @getMonsterAt(xy)
				if m?
					continue

				possible_lst.push(xy)

		if possible_lst.length == 0
			return null
		else
			return possible_lst.random()

	# mmmmonsters
	setMonsterAt: (xy, mob_or_newt) ->
		@monsters[xy.toKey()] = mob_or_newt
		mob_or_newt.setLocation(xy)
		true
	
	removeMonsterAt: (xy) ->
		delete @monsters[xy.toKey()]
		true
		
	getMonsterAt: (xy) ->
		if not xy?
			debugger
		return @monsters[xy.toKey()]
	
	getMonsters: () ->
		return (mob for own key, mob of @monsters)
		
	getMonsterById: (id) ->
		monsters = @getMonsters()
		id_list = (m.id for m in monsters)
		idx = id_list.indexOf(id)
		if idx == -1
			return null
		else
			return monsters[idx]
			
	# items
	setItemAt: (xy, item) ->
		@items[xy.toKey()] = item
		item.setLocation(xy)
		true
	
	removeItemAt: (xy) ->
		delete @items[xy.toKey()]
		true
		
	getItemAt: (xy) ->
		return @items[xy.toKey()]		
	
	getItems: () ->
		return (item for own key, item of @items)
		
	# lights!
	setLightAt: (xy, color) ->
		@light[xy.toKey()] = ROT.Color.add(color, @ambient_light)
		true
		
	getLightAt: (xy) ->
		light_at = @light[xy.toKey()]
		return light_at ? @ambient_light
	
	getLightAt_NoAmbient: (xy) ->	
		return @light[xy.toKey()]
		
	clearLights: ->
		@light = {}
		true
	
	# portals
	setUnlinkedPortalAt: (xy) ->
		@portals[xy.toKey()] = new Portal()

	setLinkedPortalAt: (xy, to_level_id, to_level_xy) ->
		@portals[xy.toKey()] = new Portal(to_level_id, to_level_xy)
		
	getPortalAt: (xy) ->
		return @portals[xy.toKey()]
		
	# dungeon features -> sit on top of and modify terrain
	setFeatureAt: (xy, thing) ->
		@features[xy.toKey()] = thing
		thing.setLocation(xy)
		true
	
	removeFeatureAt: (xy) ->
		delete @features[xy.toKey()]
		true
		
	getFeatureAt: (xy) ->
		return @features[xy.toKey()]		
	
	getFeatures: () ->
		return (f for own key, f of @features)
		
	# stuff that shows up in the LAYER display -> gas, projectiles, etc (also features)
	setOverheadAt: (xy, thing) ->
		@overheads[xy.toKey()] = thing
		thing.setLocation(xy)
		true
	
	removeOverheadAt: (xy) ->
		delete @overheads[xy.toKey()]
		true
		
	getOverheadAt: (xy) ->
		return @overheads[xy.toKey()]		
	
	getOverheads: () ->
		return (f for own key, f of @overheads)

	# AGENTS - get turns like monsters but not really monsters
	setAgentAt: (xy, agent) ->
		@agents[xy.toKey()] = agent
		agent.setLocation(xy)
		true
	
	removeAgentAt: (xy) ->
		delete @agents[xy.toKey()]
		true
		
	getAgentAt: (xy) ->
		if not xy?
			debugger
		return @agents[xy.toKey()]
	
	getAgents: () ->
		return (a for own key, a of @agents)
		

class Portal
	constructor: (to_level_id, level_xy) ->
		@to_level_id = to_level_id ? -1
		@level_xy = level_xy ? null

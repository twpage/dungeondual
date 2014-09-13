class window.Brew.Game
	constructor: (display_info, @game_id, @user_id, @gamekey) ->
		@levels = {}
		@pathmaps = {}
		@my_level = null
		@my_player = null
		@intel = null
		@turn = 0
		@levelgen = null
		@animations = []
		@scheduler = new ROT.Scheduler.Speed()
		@ui = new Brew.UserInterface(@, display_info)
		@abilities = null
		@levelseeds = []

		## socket pair
		@socket = new Brew.Socket(@)
		@is_paired = false
		@pair = {}
		@lastKeypress = 0
		@idle = 0
		@incoming_ability = {}
		@incoming_monster = {}
		@incoming_item = {}
		
		@item_catalog = {}

	# send all keypresses to the user_interface class
	keypress: (e) -> 
		# now = new Date()
		# diff = now - @lastKeypress
		# console.log("time: " + diff)
		@ui.keypress(e)
		@lastKeypress = new Date()

	start: (player_name, hero_type) ->
		@my_player = @createPlayer(hero_type)
		@my_player.name = player_name

		@intel = new Brew.Intel(@)
		@abil = new Brew.AbilityCode(@)

		$.ajax(
			url: "/ajax/levelseeds/#{@gamekey}"
			success: (json_response) => 
				@finishStart(json_response)
			dataType: "json"
		)

	finishStart: (json_response) ->
		# grab the seeds from the server
		@levelseeds = json_response["data"]

		# randomize our items
		@randomizeItemCatalog(@levelseeds[0])

		# build the first level
		@levelgen = new Brew.LevelGenerator(@)
		id = @createLevel(0, @levelseeds[0])
		@setCurrentLevel(id)

		setInterval(() =>
			@interval()
		, 5000
		)

	interval: () ->
		# called by browser every X second(s)
		
		# if we dont have a pair, do nothing
		if not @is_paired
			@socket.requestDisplayUpdate()

		# time since last keypress 
		# figure out if player is "rushing" or "thinking"
		now = new Date()
		@idle = now - @lastKeypress

		# if we just started, send an update
		if @lastKeypress == 0
			@socket.sending = true
			@socket.sendDisplayUpdate()
			@socket.sending = false

		# if we are idle, dont send anything
		else if @idle > 5000
			# console.log("idle, send nothing")
			return

		# if we have moved recently, send an update
		else 
			# console.log("SEND UPDATE")
			@socket.sendDisplayUpdate()

	randomizeItemCatalog: (seed) ->
		# randomizes names of flasks and stuff
		
		ROT.RNG.setSeed(seed)

		# flasks
		Brew.flaskNames = Brew.flaskNames.randomize()

		i = 0
		for own blah, flask_type of Brew.flaskTypes
			random_name = Brew.flaskNames[i]
			Brew.flaskType[flask_type].unidentified_name = "#{random_name} Flask"
			Brew.flaskType[flask_type].is_identified = false
			# console.log("#{random_name} is #{flask_type}")
			i += 1

	isIdentified: (item) ->
		if item.group == Brew.groups.FLASK

			return Brew.flaskType[item.flaskType].is_identified

		else
			return true

	getItemDescription: (item) ->
		if item.group == Brew.groups.FLASK
			if Brew.flaskType[item.flaskType].is_identified
				desc = Brew.flaskType[item.flaskType].description
			else
				desc = "Its contents are a mystery"

		else
			desc = item.description ? "Seems normal enough"

		return desc


	getItemNameFromCatalog: (item) ->
		# flasks are randomized
		if item.group == Brew.groups.FLASK

			if Brew.flaskType[item.flaskType].is_identified
				name = Brew.flaskType[item.flaskType].real_name
			else
				name = Brew.flaskType[item.flaskType].unidentified_name

		# otherwise no randomizing
		else
			name = item.name

		# see if it came from another player
		if item.owner?
			return "#{item.owner}'s #{name}"
		else
			return name

	createPlayer: (hero_type) ->
		console.log(hero_type)
		player = Brew.monsterFactory("PLAYER")
		player.inventory.addItem(Brew.itemFactory("TIME_ORB"))
		# player.inventory.addItem(Brew.itemFactory("WPN_HAMMER"))
		player.hero_type = hero_type
		player.createStat(Brew.stat.stamina, Brew.hero_type[hero_type].stamina)
		player.createStat(Brew.stat.health, Brew.hero_type[hero_type].hp)

		for ability in Brew.hero_type[hero_type].start_abilities
			player.addAbility(ability)

		# player.addAbility(Brew.abilities.charge)
		# player.addAbility(Brew.abilities.warcry)
		# player.addAbility(Brew.abilities.defend)
		# player.addAbility(Brew.abilities.banish)
		# player.addAbility(Brew.abilities.fireball)

		# player.addAbility(Brew.abilities.fireball)
		# player.addAbility(Brew.abilities.entangle)
		# player.addAbility(Brew.abilities.forcebolt)

		return player
		
	refreshScheduler: () ->
		# clear and rebuild the scheduler
		@scheduler.clear()
		for mob in @my_level.getMonsters()
			@scheduler.add(mob, true)

		for agent in @my_level.getAgents()
			@scheduler.add(agent, true)

		@endPlayerTurn()

	updatePathMapsFor: (monster, calc_from) ->
		calc_from ?= false # assume we aren't running away
		monster.pathmaps[Brew.paths.to_player] = Brew.PathMap.createMapToPlayer(@my_level, @my_player.coordinates, monster, 10)
		
		if calc_from
			monster.pathmaps[Brew.paths.from_player] = Brew.PathMap.createMapFromPlayer(@my_level, @my_player.coordinates, monster, monster.pathmaps[Brew.paths.to_player], 10)
	
	setCurrentLevel: (level_id, arrive_xy) ->
		# setup screen/player for a new level
		@my_level = @levels[level_id]

		@my_level.setMonsterAt((if arrive_xy? then arrive_xy else @my_level.start_xy), @my_player)
		@my_level.updateLightMap()

		@refreshScheduler()

		# update all FOVs
		@updateAllFov()
		@ui.centerViewOnPlayer()
		@ui.drawDisplayAll()
		@ui.drawHudAll()
		
	updateAllFov: () ->
		for monster in @my_level.getMonsters()
			if monster.objtype == "monster"
				monster.updateFov(@my_level)
		true

	changeLevels: (portal) ->
		if portal.to_level_id == -1
			# create a new level, then switch to it
			seed = @levelseeds[@my_level.depth + 1]
			next_id = @createLevel(@my_level.depth + 1, seed)
			next_level = @levels[next_id]
			next_level.setLinkedPortalAt(next_level.start_xy, @my_level.id, @my_level.exit_xy) # back up to this one
			@my_level.setLinkedPortalAt(@my_level.exit_xy, next_id, next_level.start_xy) # update link downwards
			@setCurrentLevel(next_id, next_level.start_xy)
			
		else
			# level already exists
			@setCurrentLevel(portal.to_level_id, portal.level_xy)

	createLevel: (depth, level_seed) ->
		level = @levelgen.create(depth, Brew.config.level_tiles_width, Brew.config.level_tiles_height, {}, level_seed)
		@levels[level.id] = level
		$.ajax(
			url: "/ajax/progress/#{@game_id}/#{@user_id}/#{depth}/"
			success: (json_response) => 
				return
			dataType: "json"
		)
		return level.id
		
	canApply: (item, applier) ->
		applier ?= @my_player
		return (
			applier.inventory.hasItem(item) and
			Brew.group[item.group].canApply
		)
	
	canEquip: (item, equipee) ->
		equipee ?= @my_player
		return (
			equipee.inventory.hasItem(item) and
			Brew.group[item.group].canEquip
		)

	canRemove: (item, equipee) ->
		equipee ?= @my_player
		return (
			equipee.inventory.hasItem(item) and
			Brew.group[item.group].equip_slot and 
			item.equip?
		)
	
	canDrop: (item, dropper) ->
		dropper ?= @my_player
		return (dropper.inventory.hasItem(item) and 
			item.group != Brew.groups.ORB
		)

	canMove: (monster, terrain) ->
		if terrain.blocks_walking
			if terrain.can_open? and terrain.can_open
				return true
			else
				if monster.hasFlag(Brew.flags.is_flying) and not terrain.blocks_flying
					return true
				else
					return false
		else
			return true

	msg: (text) ->
		console.log(text)
		# @addMessage(text)
		@ui.drawMessagesPanel(text)

	msgFrom: (monster, text) ->
		# only show message if playe can see the monster
		if @my_player.hasKnowledgeOf(monster)
			@msg(text)

	doPlayerMoveTowards: (destination_xy) ->
		# called to move the player from a mouse click

		# only pathfind to a place we have been before
		knows_path = @my_player.canView(destination_xy) or @my_player.getMemoryAt(@my_level.id, destination_xy)?
		offset_xy = null

		if knows_path
			path = @findPath_AStar(@my_player, @my_player.coordinates, destination_xy)
		
			if path?
				next_xy = path[1]
				offset_xy = next_xy.subtract(@my_player.coordinates).asUnit()

		if not offset_xy?
			# just use simple directional offset
			offset_xy = destination_xy.subtract(@my_player.coordinates).asUnit()

		@movePlayer(offset_xy)
		
	movePlayer: (offset_xy) ->
		# potentially move the player to a new location or interact with that location
		new_xy = @my_player.coordinates.add(offset_xy)
		
		monster = @my_level.getMonsterAt(new_xy)
		agent = @my_level.getAgentAt(new_xy)
		t = @my_level.getTerrainAt(new_xy)
		
		if not @my_level.checkValid(new_xy)
			@msg("You can't go that way")
			
		else if monster? #.objtype == "monster"
			@doPlayerBumpMonster(monster)
			
		else if agent?
			takesTurn = Brew.Agent.interactWithAgent(@, @my_level, @my_player, agent)
			if takesTurn
				@endPlayerTurn()

		else if t.blocks_walking and not (@my_player.hasFlag(Brew.flags.is_flying) and not t.blocks_flying)
			if t.can_apply?
				@doPlayerApplyTerrain(t, true)
					
			else
				@msg("You can't move there")

		else
			# otherwise just move around
			@moveThing(@my_player, new_xy)
			@endPlayerTurn()

	getApplicableTerrain: (thing) ->
		# return a list of any terrain apply-able around a player/thing
		
		# neighbors = thing.coordinates.getSurrounding()
		neighbors = thing.coordinates.getAdjacent()
		# neighbors.push(thing.coordinates) # probably cant apply something you are standing on
		
		apply_list = []
		for xy in neighbors
			t = @my_level.getTerrainAt(xy)
			if t? and t?.can_apply == true
				apply_list.push([
					xy.subtract(thing.coordinates),
					t]
				)
				
		return apply_list
		
	applyTerrain: (terrain, applier, bump) ->
		# apply some terrains, return true if something turn-ending happened
		if Brew.utils.isTerrain(terrain, "DOOR_CLOSED")
			@my_level.setTerrainAt(terrain.coordinates, Brew.terrainFactory("DOOR_OPEN"))
			return true
		
		else if Brew.utils.isTerrain(terrain, "DOOR_OPEN")
			@my_level.setTerrainAt(terrain.coordinates, Brew.terrainFactory("DOOR_CLOSED"))
			return true
			
		# else if Brew.utils.isTerrain(terrain, "ALTAR") and not bump
		# 	@msg("Your puny Gods cannot help you!")
		# 	return false
			
		@msg("You aren't sure how to apply that " + terrain.name)
		return false
		
	moveThing: (thing, new_xy, swap_override) ->
		swap_override ?= false

		# check for unwalkable but pathable terrain
		t = @my_level.getTerrainAt(new_xy)
		if Brew.utils.isTerrain(t, "DOOR_CLOSED")
			@applyTerrain(t, thing, true)
			return false # return false.. no successful movement 

		existing_monster = @my_level.getMonsterAt(new_xy)
		if existing_monster? and swap_override
			old_xy = thing.coordinates
			@my_level.setMonsterAt(new_xy, thing)
			@my_level.setMonsterAt(old_xy, existing_monster)

		else if existing_monster? and not swap_override
			console.error("attempting to move monster to location with existing monster")
			return false
		else
			old_xy = thing.coordinates
			@my_level.removeMonsterAt(old_xy)			
			@my_level.setMonsterAt(new_xy, thing)

		return true


	doPlayerAction: ->
		item = @my_level.getItemAt(@my_player.coordinates)
		portal = @my_level.getPortalAt(@my_player.coordinates)

		# interact with item on floor
		if item?
			# show info on screen
			if item.group == Brew.groups.INFO
				@ui.popup.context = "info"
				@ui.popup.item = item
				@ui.showInfoScreen()
			
			# corpse!
			else if item.group == Brew.groups.CORPSE
				@msg("You don't want to pick that up.")

			# pickup
			else
				@doPlayerPickup(item)
		
		# change levels
		else if portal?
			@changeLevels(portal)
		
		# rest / skip
		else
			@doPlayerRest()
			
	doPlayerRest: () ->
		if @is_paired and @pair.sync.status
			recharge = 2
		else
			recharge = 1
		
		## cant rest during combat
		last_attacked = @my_player.last_attacked ? 0
		if (@turn - last_attacked) > Brew.config.wait_to_heal and (not @my_player.hasFlag(Brew.flags.poisoned))
			@my_player.getStat(Brew.stat.stamina).addTo(recharge)
			@ui.drawHudAll()
		@endPlayerTurn()	
	
	# doPlayerThrow: (item, inv_key, target_xy) ->
	# 	actual_xy = @getActualImpactFromTarget(@my_player.coordinates, target_xy)
	# 	traverse_lst = Brew.utils.getLineBetweenPoints(@my_player.coordinates, actual_xy)

	# 	if item.equip?
	# 		@my_player.inventory.unequipItem(item)
	# 		@ui.drawHudAll()

	# 	@my_player.inventory.removeItemByKey(inv_key)
	# 	# todo: if item is present at destination, move over
		
	# 	@addAnimation(new Brew.ThrownAnimation(@my_player, item, traverse_lst))
	# 	@endPlayerTurn()

	getActualImpactFromTarget: (start_xy, target_xy, projectile) ->
		# returns an xy coordinate where a projectile will land depending on obstacles

		line = Brew.utils.getLineBetweenPoints(start_xy, target_xy)
		last_xy = null
		for xy, i in line
			# ignore starting point
			if i == 0
				last_xy = xy
				continue

			t = @my_level.getTerrainAt(xy)
			if t.blocks_flying
				# terrain blocks projectile, use last good tile
				return last_xy

			m = @my_level.getMonsterAt(xy)
			if m?
				# monster at this tile, use it
				return xy

			last_xy = xy

		# otherwise use the target tile
		return last_xy

	doPlayerPickup: (item) ->
		inv_key = @my_player.inventory.addItem(item)
		if not inv_key
			@msg("My inventory is full!")
		else
			@my_level.removeItemAt(@my_player.coordinates)
			@msg("Picked up " + @getItemNameFromCatalog(item) + " (" + item.inv_key_lower + ")")
			@endPlayerTurn()
	
	doPlayerDrop: (item) ->
		if not item
			return false

		item_at = @my_level.getItemAt(@my_player.coordinates)
		if item_at?
			@msg("There's something on the ground here already.")
			return false
		
		if item.group == Brew.groups.TIMEORB
			@msg("You dare not drop the Time Orb.")
			return false

		if item.equip?
			@doPlayerRemove(item)
			
		@my_player.inventory.removeItemByKey(item.inv_key)
		@my_level.setItemAt(@my_player.coordinates, item)
		@msg("I'll just leave this here: " + @getItemNameFromCatalog(item))
		return true
		
	doPlayerGive: (item) ->
		if not item
			return false

		if item.group == Brew.groups.TIMEORB
			@msg("The Time Orb will not travel realms.")
			return false

		if not @is_paired
			@msg("You sense no one to give this to.")
			return false

		if @is_paired and not @pair.sync.status
			@msg("You are too far from your ally.")
			return false

		if item.equip?
			@doPlayerRemove(item)
			
		@my_player.inventory.removeItemByKey(item.inv_key)
		# @my_level.setItemAt(@my_player.coordinates, item)
		@socket.sendItem(item)
		@msg("You send #{@getItemNameFromCatalog(item)} to #{@pair.username}")
		return true

	doPlayerEquip: (item) ->
		if not item
			return false
		
		slot = Brew.group[item.group].equip_slot

		if not slot?
			@msg("You're not sure where to put that...")
			return false

		existing = @my_player.inventory.getEquipped(slot)
		if existing?
			@doPlayerRemove(existing)
			
		@my_player.inventory.equipItem(item, slot)
		@msg("You are " + Brew.group[item.group].equip_verb + " " + @getItemNameFromCatalog(item) + " (" + item.inv_key_lower + ")")
		@ui.drawHudAll()
		return true
	
	doPlayerRemove: (item) ->
		if not item
			return false
		if not @canRemove(item)
			if not @canEquip(item)
				@msg("I'm not sure how to remove that.")
			else
				@msg("That's not equipped.")
			return false
			
		@my_player.inventory.unequipItem(item)
		@msg("You've stopped " + Brew.group[item.group].equip_verb + " " + @getItemNameFromCatalog(item) + " (" + item.inv_key_lower + ")")
		@ui.drawHudAll()
		return true
			
	doPlayerApply: (item, inv_key) ->
		if not item
			return false

		if not @canApply(item)
			@msg("I'm can't apply that.")
			return false
		
		@applyItem(@my_player, item)
		
		true
		
	doPlayerApplyTerrain: (terrain, bump) ->
		success = @applyTerrain(terrain, @my_player, bump)
		if success
			@endPlayerTurn()
	
	applyItem: (applier, item) ->
		# let's do this
		
		if item.group == Brew.groups.TIMEORB
			if not @is_paired
				@msg("The Time Orb looks dull and lifeless")
			else if @is_paired and not @pair.sync.status
				@msg("The Time Orb glows faintly")
			else
				@msg("The Time Orb pulses with light")
			
		else if item.group == Brew.groups.FLASK
			@msg("You open #{@getItemNameFromCatalog(item)}...")
			@useFlask(@my_player, item)
			@my_player.inventory.removeItemByKey(item.inv_key)

			
		else
			throw "error - non-appliable item"
			
	useFlask: (user, flask) ->
		if flask.flaskType == Brew.flaskTypes.fire
			@setFlagWithCounter(user, Brew.flags.on_fire, 5)
			@msg("You are on fire!")
			@ui.drawMapAt(user.coordinates)

		else if flask.flaskType == Brew.flaskTypes.health
			@msg("Your health improves!")
			user.getStat(Brew.stat.health).addToMax(1)
			user.getStat(Brew.stat.health).reset()

			@ui.drawHudAll()

		else if flask.flaskType == Brew.flaskTypes.weakness
			@msg("A wave of weakness overwhelms you")
			user.getStat(Brew.stat.stamina).setTo(0)
			@ui.drawHudAll()

		else if flask.flaskType == Brew.flaskTypes.might
			@setFlagWithCounter(user, Brew.flags.is_mighty, 20)
			@msg("Supernatural strength flows through you")
			@ui.drawMapAt(user.coordinates)

		else if flask.flaskType == Brew.flaskTypes.invisible
			@setFlagWithCounter(user, Brew.flags.invisible, 10)
			@msg("You can see right through yourself!")
			@ui.drawMapAt(user.coordinates)

		else if flask.flaskType == Brew.flaskTypes.vigor
			@msg("This makes you feel amazing!")
			user.getStat(Brew.stat.stamina).addToMax(1)
			user.getStat(Brew.stat.stamina).reset()
			@ui.drawHudAll()

		else
			console.error("unexpected flask item", flask)

		# identify this item
		Brew.flaskType[flask.flaskType].is_identified = true

		return true


	doPlayerBumpMonster: (bumpee) ->
		# shove / ally swap / feature interact 
		if bumpee.objtype == "monster"
			@meleeAttack(@my_player, bumpee)
			
		else if bumpee.objtype == "agent"
			Brew.Actor.handleBump(@, @my_player, bumpee)
			
		else
			throw "a horrible error happened when bumping a monster"
			
		@endPlayerTurn()
	
	canAttack: (attacker, target_mob) ->
		# returns true if melee or ranged attack is possible

		attack_range = attacker.getAttackRange()
		
		if attack_range == 0
			return false
		
		else if attack_range == 1
			# melee
			return (xy for xy in attacker.coordinates.getAdjacent() when xy.compare(target_mob.coordinates)).length > 0

		else if attack_range == 1.5
			# special melee + diagonal
			return (xy for xy in attacker.coordinates.getSurrounding() when xy.compare(target_mob.coordinates)).length > 0
			
		else
			return @checkRangedAttack(attacker, target_mob)

	checkRangedAttack: (attacker, target) ->
		# returns true if an attacker can hit a given target

		# can't shoot if you don't know it is there
		if not attacker.hasKnowledgeOf(target)
			return [false, Brew.errors.ATTACK_NOT_KNOWN, []]

		# can't shoot what you can't see (should be same as above)
		if not attacker.canView(target.coordinates)
			return [false, Brew.errors.ATTACK_NOT_VISIBLE, []]

		# too far away?
		dist = Brew.utils.dist2d(attacker.coordinates, target.coordinates)
		if dist > attacker.getAttackRange()
			return [false, Brew.errors.ATTACK_OUT_OF_RANGE, []]

		# make sure nothing is in the way
		start_xy = attacker.coordinates
		target_xy = target.coordinates
		traverse_lst = Brew.utils.getLineBetweenPoints(start_xy, target_xy)
		
		# ignore first and last points
		if traverse_lst.length < 2
			throw "Traversal path should never be less than 2"
		else
			len = traverse_lst.length
			traverse_lst = traverse_lst[1..len-1]

		# make sure there aren't any other monsters in the way
		for xy in traverse_lst
			t = @my_level.getTerrainAt(xy)
			if t.blocks_walking
				return [false, Brew.errors.ATTACK_BLOCKED, []]

			m = @my_level.getMonsterAt(xy)
			if m? and not Brew.utils.compareThing(m, attacker) and not Brew.utils.compareThing(m, target)
				return [false, Brew.errors.ATTACK_BLOCKED, []]

		return [true, "OK", traverse_lst]
			
	meleeAttack: (attacker, defender) ->
		return @attack(attacker, defender, true)
		
	doMonsterAttack: (monster, defender) ->
		# called by the execute monster action function 
		# call melee or ranged attacks as necessary

		neighbors = defender.coordinates.getSurrounding()
		is_melee = neighbors.some((xy) -> monster.coordinates.compare(xy))

		if not is_melee
			# animate before calling the attack function
			start_xy = monster.coordinates
			target_xy = defender.coordinates

			traverse_lst = Brew.utils.getLineBetweenPoints(start_xy, target_xy)
			traverse_lst = traverse_lst[1..traverse_lst.length - 1]
			
			laserbeam = Brew.featureFactory("PROJ_MONSTERBOLT", {
				code: Brew.utils.getLaserProjectileCode(start_xy, target_xy)
				damage: monster.damage
			})
		
			@addAnimation(new Brew.ProjectileAnimation(monster, laserbeam, traverse_lst))
			# console.log(traverse_lst)

		else
			@attack(monster, defender, is_melee)

	attack: (attacker, defender, is_melee, options) ->
		options ?= {}

		defender.last_attacked = @turn

		attacker_is_player = attacker.group == "player"
		
		if not defender?
			debugger
		defender_is_player = defender.group == "player"

		combat_msg = ""
		if attacker_is_player
			combat_msg += "You "
			combat_msg += if is_melee then "punch " else "fire at "
			combat_msg += "the " + defender.name
		else
			combat_msg += "The " + attacker.name + " "
			combat_msg += if is_melee then "attacks " else "shoots at "
			combat_msg += if defender_is_player then "you" else "the " + defender.name

		if not options.remote?
			@msg(combat_msg)
		
		## WEAPON - figure out which weapon we are using
		weapon = null
		equipped_wpn = attacker.inventory?.getEquipped(Brew.equip_slot.melee)
		if options.remote?
			weapon = options.remote

		else if equipped_wpn?
			weapon = equipped_wpn

		## DAMAGE
		if not weapon?
			damage = attacker.getAttackDamage(is_melee)
		else
			damage = weapon.damage
		
		# damage multipliers
		if attacker.hasFlag(Brew.flags.is_mighty)
			damage = Math.floor(damage * Brew.config.mighty_damage_mult)

		# 7drl fix to make it less painful
		if attacker_is_player
			damage += Brew.config.damage_fix

		defender_armor = defender.inventory?.getEquipped(Brew.equip_slot.body)
		if defender_armor?
			console.log("armor block")
			block = defender_armor.block ? 1
			damage = Math.max(0, damage - block)

		if defender.hasFlag(Brew.flags.defended)
			damage = Math.max(1, damage - Brew.config.defended_block)

		console.log("damage was ", damage)

		## Apply damage, track overkill amount for later use (?)
		if defender_is_player
			# reduce from stamina first
			damage = defender.getStat(Brew.stat.stamina).deductOverflow(damage)

		overkill = defender.getStat(Brew.stat.health).deductOverflow(damage)

		# remove flags when hit
		if damage > 0 and defender.hasFlag(Brew.flags.stunned)
			defender.removeFlagCounter(Brew.flags.stunned)
			defender.removeFlag(Brew.flags.stunned)

		## apply any attack options
		if not options?.noEffects
			@attackEffects(attacker, defender, weapon, is_melee, damage)
		
		## check for death -- ouch
		is_dead = defender.getStat(Brew.stat.health).isZero()
		
		@ui.drawHudAll()

		# draw some gore on each hit
		splat = Brew.utils.createSplatter(defender.coordinates, 3)
		for own key, intensity of splat
			xy = keyToCoord(key)
			t = @my_level.getTerrainAt(xy)
			if t.show_gore
				@my_level.setFeatureAt(xy, Brew.featureFactory("BLOOD", {intensity: intensity}))

		# animate melee attacks when the defender doesn't die
		if is_melee and not is_dead
			flash_color = Brew.colors.red
			@addAnimation(new Brew.FlashAnimation(clone(defender.coordinates), flash_color))

		else
			@finishAttack(attacker, defender, is_melee, overkill)

	finishAttack: (attacker, defender, is_melee, overkill) ->
		is_dead = defender.getStat(Brew.stat.health).isZero()
		defender_is_player = defender.group == "player"

		if is_dead and defender_is_player
			@killPlayer(attacker, defender, is_melee, overkill)
		else if is_dead
			@killMonster(attacker, defender, is_melee, overkill)
		
		true

	remoteImpact: (attacker, location_xy, weapon) ->
		# called from animations, can strike a location or impact a monster at that location
		m = @my_level.getMonsterAt(location_xy)
		if m?
			@attack(attacker, m, false, {remote: weapon})

	killPlayer: (killer, victim_player, is_melee, overkill_damage) ->
		console.log("you died!")
		$.ajax(
			url: "/ajax/died/#{@game_id}/#{@user_id}/#{ @my_level.depth + 1}/#{ killer.name }/"
			success: (json_response) => 
				@finishKillPlayer(json_response)
			dataType: "json"
		)

	finishKillPlayer: (json_response) ->
		@ui.showDied()

	killMonster: (attacker, victim, is_melee, overkill_damage) ->
		dead_xy = clone(victim.coordinates)

		@msg("You kill the " + victim.name)
		victim.is_dead = true
		if victim.light_source?
			@my_level.updateLightMap()
		
		@my_level.removeMonsterAt(victim.coordinates)
		@scheduler.remove(victim)
		@ui.drawMapAt(dead_xy)

		if victim.def_id == "TIME_MASTER"
			@doVictory()

	doVictory: () ->
		console.log("you won!")
		$.ajax(
			url: "/ajax/victory/#{@game_id}/"
			success: (json_response) => 
				@finishVictory(json_response)
			dataType: "json"
		)

	finishVictory: (json_response) ->
		@ui.showVictory()

	attackEffects: (attacker, defender, attack_wpn, is_melee, damage) ->
		# attack_wpn = attacker.inventory?.getEquipped(Brew.equip_slot.melee)
		defender_is_player = Brew.utils.compareThing(defender, @my_player)

		# pierce through 2 enemies
		if attack_wpn? and attack_wpn.hasFlag(Brew.flags.weapon_pierce) 
			offset_xy = defender.coordinates.subtract(attacker.coordinates).multiply(2)
			effect_xy = attacker.coordinates.add(offset_xy)
			monster_at = @my_level.getMonsterAt(effect_xy)
			if monster_at?
				@attack(attacker, monster_at, is_melee)

		# smash all surrounding enemies
		else if attack_wpn? and attack_wpn.hasFlag(Brew.flags.weapon_smash)
			for effect_xy in attacker.coordinates.getSurrounding()
				# don't double-count current defender
				if effect_xy.compare(defender.coordinates)
					continue

				monster_at = @my_level.getMonsterAt(effect_xy)
				if monster_at?
					@attack(attacker, monster_at, is_melee, {noEffects: true})

		# auto stun
		else if attack_wpn? and attack_wpn.hasFlag(Brew.flags.weapon_stun)
			if not defender.hasFlag(Brew.flags.stunned) # cant stun if already stunned
				@msg("#{defender.name} is stunned!")
				@setFlagWithCounter(defender, Brew.flags.stunned, 5)

		# chance stun
		else if attack_wpn? and attack_wpn.hasFlag(Brew.flags.weapon_stun_chance)
			if ROT.RNG.getUniform() < Brew.config.stun_chance
				if not defender.hasFlag(Brew.flags.stunned) # cant stun if already stunned
					@msg("#{defender.name} is stunned!")
					@setFlagWithCounter(defender, Brew.flags.stunned, 5)

		# burning
		else if (attack_wpn? and attack_wpn.hasFlag(Brew.flags.weapon_burning)) or attacker.hasFlag(Brew.flags.weapon_burning)
			@setFlagWithCounter(defender, Brew.flags.on_fire, 5)
			if defender_is_player
				@msg("You are on fire!")
			else
				@ui.showDialogAbove(defender.coordinates, Brew.Messages.getRandom("burning"))

		# poison
		else if (attack_wpn? and attack_wpn.hasFlag(Brew.flags.weapon_poison)) or attacker.hasFlag(Brew.flags.weapon_poison)
			@setFlagWithCounter(defender, Brew.flags.poisoned, 5)
			if defender_is_player
				@msg("You've been poisoned!")
			else
				@ui.showDialogAbove(defender.coordinates, "Ack!", Brew.colors.green)


	endPlayerTurn: () ->
		# update player pathmaps
		@turn += 1
		@pathmaps[Brew.paths.to_player] = Brew.PathMap.createGenericMapToPlayer(@my_level, @my_player.coordinates, 10)
		@checkForIncoming()
		@nextTurn()

	animationTurn: (animation) ->
		animation.runTurn(@, @ui, @my_level)
		if not animation.active
			@removeAnimation(animation)
		@finishEndPlayerTurn({update_all: animation.over_saturate, over_saturate: animation.over_saturate})
		setTimeout(=>
			@nextTurn()
		Brew.config.animation_speed)
		return

	nextTurn: () ->
		if @hasAnimations()
			first_animation = @animations[0]
			@animationTurn(first_animation)
			return
		
		next_actor = @scheduler.next()

		if next_actor.group == "player"
			# console.log("nextTurn: player is up, #queue: " + @scheduler._repeat.length)
			@checkFlagCounters(next_actor)
			@finishEndPlayerTurn({update_all: true, over_saturate: false})
			@updatePairSync()
			return

		if next_actor.objtype == "monster"
			monster = next_actor
			if monster.is_dead?
				console.error("trying to run a turn on a dead monster, should be removed from scheduler")
				debugger
					
			# console.log(monster.name + "'s turn, #queue: " + @scheduler._repeat.length)

			monster.updateFov(@my_level)
			@checkFlagCounters(next_actor)
			@intel.doMonsterTurn(monster)
			@finishEndPlayerTurn()
			@nextTurn()
			return

	finishEndPlayerTurn: (options) ->
		options ?= {}
		updateAll = options.update_all ? false
		overSaturate = options.over_saturate ? false

		# update the screen
		if updateAll
			@my_level.updateLightMap()
			@updateAllFov()
			@ui.centerViewOnPlayer()
			@ui.drawDisplayAll({over_saturate: overSaturate})
			
	findPath_AStar: (thing, start_xy, end_xy) ->
		return @find_AStar(thing, start_xy, end_xy, false)
		
	findMove_AStar: (thing, start_xy, end_xy) ->
		return @find_AStar(thing, start_xy, end_xy, true)
		
	find_AStar: (thing, start_xy, end_xy, returnNextMoveOnly) ->
		passable_fn = (x, y) =>
			xy = new Coordinate(x, y)
			t = @my_level.getTerrainAt(xy)
			
			if t?
				if not @canMove(thing, t)
					return false
				else
					# terrain is passable but check for monsters
					m = @my_level.getMonsterAt(xy)
					if m?
						if thing.group == "player"
							return true
						else if thing.id == m.id
							return true
						else
							return false
					else
						return true
			else
				# probably shouldnt be here
				return false
			
		path = []			
		update_fn = (x, y) ->
			path.push(new Coordinate(x, y))

		astar = new ROT.Path.AStar(end_xy.x, end_xy.y, passable_fn, {topology: 4})
		astar.compute(start_xy.x, start_xy.y, update_fn)

		next_xy = path[1]
		
		if returnNextMoveOnly
			return next_xy ? null
		else
			return path

	execMonsterTurnResult: (monster, result) ->
		if result.action == "sleep"
			;
			
		else if result.action == "move"
			@moveThing(monster, result.xy)
			
		else if result.action == "wait"
			monster.giveup = if monster?.giveup then monster.giveup + 1 else 1
		
		else if result.action == "attack"
			@doMonsterAttack(monster, result.target)
			
		else if result.action == "stand"
			# monster is keeping its distance but doesn't need to move (usually would attack)
			# different from waiting because they wont give up after a while
			if ROT.RNG.getUniform() < 0.25
				@msgFrom(monster, monster.name + " glowers at you from afar.")
			;
			
		else if result.action == "special"
			# dont do anything (else)
			;
			
		else
			throw "unexpected AI result" 


	addAnimation: (new_animation) ->
		@animations.push(new_animation)

	removeAnimation: (my_animation) ->
		@animations = (a for a in @animations when a.id != my_animation.id)
		return true

	hasAnimations: () ->
		return @animations.length > 0

	doPlayerPairClick: (pair_map_xy) ->
		# try to use an active ability on the co-op game
		if @my_player.active_ability?
			if not @is_paired
				@msg("You cannot sense the other realm.")
			else if @is_paired and not @pair.sync.status
				@msg("You are too far from your ally.")
			else
				@abil.execute(@my_player.active_ability, pair_map_xy, true)

	doPlayerClick: (map_xy) ->
		# try to use an active ability
		if @my_player.active_ability?
			@abil.execute(@my_player.active_ability, map_xy, false)

	doPlayerSelectAbility: (keycode) ->
		idx = keycode - 49

		if @my_player.abilities.length == 0
			@msg("You don't have any abilities")

		else if idx >= @my_player.abilities.length
			@msg("Invalid ability number -- too high")

		else
			selected_abil = @my_player.abilities[idx]
			@doPlayerAbility(selected_abil, keycode)

	doPlayerAbility: (ability, keycode) ->
		# @my_player.active_ability = ability
		@ui.showTargeting(ability, keycode)

	# doPlayerDisableAbility: (ability) ->
	# 	@my_player.active_ability = null
	# 	console.log("No longer using #{Brew.ability[ability].name}.")
	# 	@ui.drawHudAll()

	doTargetingAt: (ability, target_xy) ->
		[can_use, data] = @abil.canUseAt(ability, target_xy)
		if not can_use
			@msg("#{data}")
			return false

		@abil.execute(ability, target_xy, false)
		return true

	checkForIncoming: () ->
		# called right before player turn
		# console.log("calling executeIncomingAbility")

		if @incoming_ability.ability?
			ability = @incoming_ability.ability
			from_xy = coordFromObject(@incoming_ability.from_xy)
			to_xy = coordFromObject(@incoming_ability.to_xy)

			@incoming_ability = {}

			if ability == Brew.abilities.fireball
				@abil.fireball_execute(@pair.player, from_xy, to_xy)

			else if ability == Brew.abilities.entangle
				@abil.entangle_execute(@pair.player, from_xy, to_xy)

			else if ability == Brew.abilities.warcry
				@abil.warcry_execute(@pair.player, from_xy, to_xy)

			else if ability == Brew.abilities.defend
				@abil.defend_execute(@pair.player, from_xy, to_xy)


			return true

		else if @incoming_monster.name?
			console.log("got a monster #{@incoming_monster}")

			xy = @my_level.getRandomWalkableLocationNear(@my_player.coordinates, 10)
			if xy?
				traveler = Brew.monsterFactory(@incoming_monster.def_id, {status: Brew.monster_status.WANDER})
				@msg("#{@pair.username} banishes #{traveler.name} to your realm")
				traveler.name = @pair.username + "'s " + traveler.name

				@my_level.setMonsterAt(xy, traveler)
				@scheduler.add(traveler, true)
				
				@ui.drawMapAt(xy)

				@incoming_monster = {}

			# if not valid xy try again next turn

			return true

		else if @incoming_item.name?
			console.log("got a item #{@incoming_item}")

			xy = @my_level.getRandomWalkableLocationNear(@my_player.coordinates, 10)
			if xy?
				item = Brew.itemFactory(@incoming_item.def_id)
				@msg("#{@pair.username} sends #{@getItemNameFromCatalog(item)} to your realm")
				item.owner = @pair.username

				@my_level.setItemAt(xy, item)
				@ui.drawMapAt(xy)

			@incoming_item = {}
			return true

		return false

	updatePairSync: () ->
		# called before each turn to see if we're in sync
		# will use most recent pair data

		in_sync = false
		message = ""

		if not @is_paired
			in_sync = false
			message = "no connection"

		else

			pair_xy = @pair.player.coordinates
			pair_level_depth = @pair.level_depth
			pair_turn = @pair.turn

			# make sure we're on the same level - otherwise no sync
			my_depth = @my_level.depth
			if my_depth != pair_level_depth
				in_sync = false
				if my_depth < pair_level_depth
					message = "Changed Levels"
				else
					message = "Changed Levels"

			# otherwise measure sync using space (2d dist) and time (turn count)
			else
				dist2d = Brew.utils.dist2d(@my_player.coordinates, pair_xy)
				turn_diff = @turn - pair_turn

				sync = Math.sqrt(
					Brew.config.sync.space*Math.pow(dist2d, 2) + 
					Brew.config.sync.time*Math.pow(turn_diff, 2)
				)
				# console.log(dist2d, turn_diff, sync)
				# console.log(sync)

				if sync <= Brew.config.sync.limit
					in_sync = true
					message = "OK"
				else
					in_sync = false
					space = Brew.config.sync.space*dist2d

					if Math.abs(turn_diff) < (Brew.config.sync.limit * Brew.config.sync.time)
						message = "Get closer"
					else if turn_diff < 0
						message = "Hurry"
					else
						message = "Wait"

			@pair.sync = 
				"status": in_sync
				"message": message
			
			@ui.drawHudSync()
			return in_sync

	updatePairGhost: (pair_xy) ->
		if not @pair.player?
			@pair.player = Brew.featureFactory("PLAYER_PAIR")
			@pair.player.name = @pair.username
			@my_level.setOverheadAt(pair_xy, @pair.player)

		current_xy = clone(@pair.player.coordinates)
		if not current_xy.compare(pair_xy)
			console.log("redrawing player ghost")
			@my_level.removeOverheadAt(current_xy)
			@my_level.setOverheadAt(pair_xy, @pair.player)
			@ui.drawMapAt(current_xy)
			@ui.drawMapAt(pair_xy)

	# handle flag timeout for temp effects, needs to know game turn
	setFlagWithCounter: (thing, flag, effect_turns) ->
		thing.setFlagCounter(flag, @turn + effect_turns)
		true

	checkFlagCounters: (thing) ->
		for flag in thing.getFlagCounters()
			end_turn = thing.getFlagCount(flag)
			if end_turn <= @turn
				thing.removeFlagCounter(flag)

				if Brew.utils.compareThing(thing, @my_player)
					@msg("You are no longer #{flag}")
				else
					@msgFrom(thing, "#{thing.name} is no longer #{flag}")

			else
				# still burning!!!

				if flag == Brew.flags.on_fire
					if Brew.utils.compareThing(thing, @my_player)
						@my_player.getStat(Brew.stat.stamina).deduct(1)
						@my_player.last_attacked = @turn
						@ui.drawHudAll()
					else
						thing.getStat(Brew.stat.health).deduct(1)
						if thing.getStat(Brew.stat.health).isZero()
							@killMonster(@my_player, thing, false, 0)

		true

	debugClick: (map_xy) ->
		debug_id = $("#id_select_debug").val()
		[objtype, def_id] = debug_id.split("-")
		if objtype == "MONSTER"
			monster = Brew.monsterFactory(def_id, {status: Brew.monster_status.WANDER})
			@my_level.setMonsterAt(map_xy, monster)
			@ui.drawMapAt(map_xy)
			@scheduler.add(monster, true)

	debugDropdownMenu: () ->
		# populate a dropdown menu with stuff
		for own def_id, monster_def of Brew.monster_def
			if def_id == "PLAYER" then continue
			$("#id_select_debug").append("<option value=\"MONSTER-#{def_id}\">#{def_id}</option>")

class window.Brew.Intel
	constructor: (@game) ->
		@id = null
		
	msg: (text) ->
		@game.msg(text)
		
	doMonsterTurn: (monster) ->
		# Agents don't need complicated AI logic
		if monster.agent
			return Brew.Agent.doAgentTurn(@game, @game.my_level, monster)

		# see if we can move
		if monster.hasFlag(Brew.flags.stunned)
			# i can't move...
			return false

		# change state if necessary
		@updateState(monster)
		
		# pick an action and then do it
		result = @getAction(monster)
		# console.log("monster #{monster.name} #{monster.id}'s turn: #{result.action} -> #{result.xy}")
		
		# do it!
		monster.last_xy = monster.coordinates
		@game.execMonsterTurnResult(monster, result)
		return true
		
	updateState: (monster) ->
		# handle state changes 
		
		# can we sense/see the player?
		me_sense_player = monster.hasKnowledgeOf(@game.my_player)
		horde_sense_player = if monster.horde? then monster.horde.hasKnowledgeOf(@game.my_player) else false
		sense_player = me_sense_player or horde_sense_player
		
		# should we run away?
		if monster.status != Brew.monster_status.ESCAPE and monster.hasFlag(Brew.flags.flees_when_wounded)
			if monster.hp < monster.maxhp
				@msg(monster.name + " flees!")
				monster.status = Brew.monster_status.ESCAPE
				return true # don't need to worry about any other state changes
		
		# SLEEP sleeping... zzzzz
		if monster.status == Brew.monster_status.SLEEP
			# chance we will wake up		
			;
			
		# WANDER
		else if monster.status == Brew.monster_status.WANDER
			# change if we notice the player
			if sense_player
				# chance we wont notice?
				verb = " spots " # if sense_player then " spots " else " senses "
				# @msg(monster.name + verb + "you!") # >:O X| 
				@game.ui.showDialogAbove(monster.coordinates, Brew.Messages.getRandom("alarm"), Brew.colors.red)
				monster.giveup = 0
				monster.status = Brew.monster_status.HUNT
				
		# HUNT
		else if monster.status == Brew.monster_status.HUNT
			# if we cant see the player, increment the giveup timer
			if !sense_player
				monster.giveup = if monster?.giveup then monster.giveup + 1 else 1
				
				# give up after a while and go back to wandering
				if monster.giveup > 4
					# @msg(monster.name + " gives up the hunt.")
					# @game.ui.showDialogAbove(monster.coordinates, "Target lost", Brew.colors.red)
					monster.giveup = 0
					monster.status = Brew.monster_status.WANDER
			
			# we can still see the player
			else
				# update where we last saw the player in case they disappear
				monster.last_player_xy = @game.my_player.coordinates
				
		# ESCAPE
		else if monster.status == Brew.monster_status.ESCAPE
			# healed?
			if monster.hp == monster.maxhp 
				monster.status = Brew.monster_status.HUNT
		
		return true
	
	getAction: (monster) ->
		# determine what the monster should be doing based on state (HUNT/WANDER/etc) 
		
		# can we sense/see the player?
		me_sense_player = monster.hasKnowledgeOf(@game.my_player)
		horde_sense_player = if monster.horde? then monster.horde.hasKnowledgeOf(@game.my_player) else false
		sense_player = me_sense_player or horde_sense_player
		
		# can we move?
		is_immobile = monster.hasFlag(Brew.flags.is_immobile)

		# here is our default action construct
		result = 
			action: null
			xy: monster.coordinates
			target: null

		# SLEEP : no action
		if monster.status == Brew.monster_status.SLEEP
			result.action = "sleep"
			
		# WANDER : continue to wander
		else if monster.status == Brew.monster_status.WANDER
			# change wander destinations after a while
			if monster.giveup > 4 or (monster.wander_xy? and monster.coordinates.compare(monster.wander_xy))
				monster.giveup = 0
				monster.wander_xy = null
				
			result.action = "move"
			result.xy = @getWanderMove(monster)
		
		# ESCAPE : run away
		else if (monster.status == Brew.monster_status.ESCAPE) or monster.hasFlag(Brew.flags.is_scared)
			# if we can see the player, update our personal escape map
			if sense_player
				@game.updatePathMapsFor(monster, true)
				
			result.action = "move"
			result.xy = @getMoveAwayFromPlayer(monster)
		
		# IMMOBILE HUNT : attack only
		else if monster.status == Brew.monster_status.HUNT and is_immobile
			if sense_player and @game.canAttack(monster, @game.my_player)
				result.action = "attack"
				result.xy = @game.my_player.coordinates
				result.target = @game.my_player
			else
				result.action = "wait"

		# HUNT : attack or move towards player
		else if monster.status == Brew.monster_status.HUNT and (not is_immobile)
			keeps_distance = monster.hasFlag(Brew.flags.keeps_distance)			
			
			# do we know where the player is?
			if sense_player
				@game.updatePathMapsFor(monster, keeps_distance)
				
				decision = @getKeepDistanceDirection(monster)

				if keeps_distance and decision == "forward"
					result.action = "move"
					result.xy = @getMoveTowardsPlayer(monster)
					
				else if keeps_distance and decision == "back" 
					result.action = "move"
					result.xy = @getMoveAwayFromPlayer(monster)
				
				else
					special_ability = @canUseSpecialAbility(monster)
					
					if special_ability
						result.action = "special"
						@doSpecialAbility(monster, special_ability)
						
					# can we attack this player?
					else if @game.canAttack(monster, @game.my_player)
						result.action = "attack"
						result.xy = @game.my_player.coordinates
						result.target = @game.my_player
					
					# no abilities, can't attack, but want to keep distance?
					else if keeps_distance
						result.action = "stand"
					
					# otherwise, move towards player
					else
						result.action = "move"
						result.xy = @getMoveTowardsPlayer(monster)
				
			else
				# we lost them but move to last location 
				result.action = "move"
				result.xy = @game.findMove_AStar(monster, monster.coordinates, monster.last_player_xy)
			
			
		# POST PROCESSING modifications to Actions
		if result.action == "move" and is_immobile # immobile monsters can't move!
			result.action = "wait"

		else if result.action == "move"
			# pathfinding returned a null
			# if result.xy == null
			if not result.xy?
				result.action = "wait"
				
			else
				# can we get to where we want to go?
				monster_at = @game.my_level.getMonsterAt(result.xy)
				if monster_at?
					# we found the player (by accident?)
					if monster_at.group == "player"
						result.action = "attack"
						result.target = @game.my_player
						
					# we ran into another monster, tell them where player is, if they are escaping
					else if monster.status == Brew.monster_status.ESCAPE and monster_at.status == Brew.monster_status.ESCAPE
						monster_at.pathmaps[Brew.paths.from_player] = monster.pathmaps[Brew.paths.from_player]
						result.action = "wait"
						
					else
						# it is another monster but we have to wait
						result.action = "wait"
						result.xy = null
						result.target = null
			
		return result
	
	getWanderMove: (monster) ->
		# see if we already have a wandering point
		if not monster.wander_xy?
			# make one
			monster.wander_xy = @game.my_level.getRandomWalkableLocation()
			
		else if monster.wander_xy.compare(monster.coordinates)
			# already there, make a new one
			monster.wander_xy = @game.my_level.getRandomWalkableLocation()
		
		# where do we want to go?
		next_xy = @game.findMove_AStar(monster, monster.coordinates, monster.wander_xy)
		return next_xy
		
	getKeepDistanceDirection: (monster) ->
		# decide what a monster trying to keep their distance should do (ahead, back, stay)
		stand_value = monster.pathmaps[Brew.paths.to_player][monster.coordinates.toKey()]
		
		if stand_value < monster.attack_range
			return "back"
		else if stand_value > monster.attack_range
			return "forward"
		else
			return "stand"
		
	getMoveAwayFromPlayer: (monster) ->
		# use personal escape map to run away!
		
		next_xy = null
		
		# check if we have an escape map
		if not monster.pathmaps[Brew.paths.from_player]?
			# uh oh
			console.log("monster tried to run away without escape map")
			next_xy = getWanderMove(monster)
			
		else
			# we have one, use it
			path_xy = Brew.PathMap.getDownhillNeighbor(monster.pathmaps[Brew.paths.from_player], monster.coordinates).xy
			if not path_xy?
				console.log("getMoveAwayFromPlayer null path")
			else
				m = @game.my_level.getMonsterAt(path_xy)
				if m? and m.group != "player" and not Brew.utils.compareThing(monster, m)
					console.log("getMoveAwayFromPlayer monster collision")
				else
					next_xy = path_xy
		
	getMoveTowardsPlayer: (monster) ->
		# use personal approach map to move towards player
		
		next_xy = null
		
		# check if we have an escape map
		# if not monster.pathmaps[Brew.paths.to_player]?
		if not @game.pathmaps[Brew.paths.to_player]?
			# uh oh
			console.log("monster tried to move towards player without map")
		
		else
			# we have one, use it
			path_xy = Brew.PathMap.getDownhillNeighbor(@game.pathmaps[Brew.paths.to_player], monster.coordinates).xy
			m = if path_xy? then @game.my_level.getMonsterAt(path_xy) else null
			
			if (not path_xy?) or (m? and m.group != "player")
				next_xy = @game.findMove_AStar(monster, monster.coordinates, @game.my_player.coordinates)
				console.log("astar override for #{monster.id}: " + next_xy)

			else
				next_xy = path_xy
		
		return next_xy
			
	canUseSpecialAbility: (monster) ->
		can_use = null
		if monster.hasFlag(Brew.flags.summons_zombies)
			# count number of zombies already on the level
			get_zombies = (m for m in @game.my_level.getMonsters() when m.group.toUpperCase() in ["ZOMBIE", "ZOMBIE_LIMB"])
			if get_zombies.length == 0
				can_use = Brew.flags.summons_zombies

		return can_use
		
	doSpecialAbility: (monster, special_ability) ->
		if special_ability == Brew.flags.summons_zombies
			# raise the dead!
			@msg(monster.name + " raises the dead!")
			if not monster.horde?
				monster.horde = new Brew.Horde([monster])
				
			zombies_at_a_time = 0
			for xy in Brew.utils.fisherYatesShuffle(monster.coordinates.getSurrounding())
				if not @game.my_level.getMonsterAt(xy)? and not @game.my_level.getTerrainAt(xy).blocks_walking
					summon_type = if (ROT.RNG.getUniform() < 0.70) then "ZOMBIE" else "ZOMBIE_LIMB"
					z = Brew.monsterFactory(summon_type, {status: Brew.monster_status.HUNT})
				
					z.color = [
						50 + Math.floor(ROT.RNG.getUniform()*200),
						50 + Math.floor(ROT.RNG.getUniform()*200),
						50 + Math.floor(ROT.RNG.getUniform()*200)
					]
					
					monster.horde.add(z)
					@game.my_level.setMonsterAt(xy, z)
					@game.scheduler.add(z, true)
					@game.ui.drawMapAt(xy)
					zombies_at_a_time += 1
					if zombies_at_a_time == 3
						break
			
			monster.horde.updateAll(monster.last_player_xy)
			return true
			
		else
			console.log("unrecognized special ability: " + special_ability)
			return false

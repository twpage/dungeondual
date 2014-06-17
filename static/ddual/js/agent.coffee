window.Brew.Agent =
	setupTerrainAgent: (game, level, mod_xy, monster_def_id, replacement_terrain_def_id) ->
		# turn terrain at a given point into something that moves around
		terrain = level.getTerrainAt(mod_xy)
		agent = Brew.monsterFactory(monster_def_id, {
			terrain: terrain, 
			replacement_terrain: Brew.terrainFactory(replacement_terrain_def_id)
		})
		level.setAgentAt(mod_xy, agent)
		game.scheduler.add(agent, true)
		
		return agent

	doAgentTurn: (game, level, agent) ->
		if (not agent.speed?) or (agent.speed == 0)
			return false

		agent_xy = clone(agent.coordinates)
		new_xy = Brew.utils.forecastNextPoint(agent)

		t = level.getTerrainAt(new_xy)
		m = level.getMonsterAt(new_xy)
		
		if not new_xy?
			console.error("unable to forecast move")
			return false
			
		is_blocked = (not level.checkValid(new_xy)) or m? or (t.blocks_walking and t.blocks_flying)
			
		if is_blocked
			console.log("crash!")
			agent.speed = 0
			level.removeAgentAt(agent_xy)
			game.scheduler.remove(agent)

			if agent.terrain.on_destroy?
				# what's under us?
				under_terrain = agent.replacement_terrain

				if Brew.utils.isTerrain(under_terrain, "CHASM")
					level.setTerrainAt(agent_xy, under_terrain)
				else
					level.setTerrainAt(agent_xy, Brew.terrainFactory(agent.terrain.on_destroy))
			
			level.calcTerrainNavigation()
			
		else
			# propegate terrain forward
			level.setTerrainAt(agent_xy, agent.replacement_terrain)
			level.removeAgentAt(agent_xy)

			# keep track of what we overrode
			agent.replacement_terrain = level.getTerrainAt(new_xy)
			level.setTerrainAt(new_xy, agent.terrain)
			level.setAgentAt(new_xy, agent)

			# re-do terrain navigation?
			# level.calcTerrainNavigation()

			game.ui.drawMapAt(agent_xy)
			game.ui.drawMapAt(new_xy)

		return true
		
	applyForceTo: (agent, start_xy, towards_xy) ->
		agent.speed = 1
		theta = Brew.utils.calcAngle(start_xy, towards_xy)
		agent.origin_xy = agent.coordinates 
		agent.angle = theta
		
	interactWithAgent: (game, level, instigator, agent) ->
		# called when player bumps into an agent
		# todo: need to ignore walking into gas and other agents -- or maybe not??
		takesTurn = true

		offset_xy = agent.coordinates.subtract(instigator.coordinates)
		away_xy = offset_xy.asUnit().multiply(5)
		@applyForceTo(agent, agent.coordinates, agent.coordinates.add(away_xy))

		return takesTurn

	forceTerrain: (game, level, forcer, terrain) ->
		# called when player smashes into smashable terrain
		
		game.msg("You smash into the #{terrain.name}.")

		# change the current terrain
		force_xy = terrain.coordinates
		level.setTerrainAt(force_xy, Brew.terrainFactory(terrain.takes_force.force_terrain))
		game.ui.drawMapAt(force_xy)

		# see if we also need a new agent to go along with this new terrain
		if terrain.takes_force.force_agent?
			terrain_agent = Brew.Agent.setupTerrainAgent(game, level, force_xy, "AGENT_TERRAIN_TRAVEL", 
				terrain.takes_force.replace_terrain)

		# no need to draw agents, they dont show up
		return true

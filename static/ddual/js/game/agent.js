// Generated by CoffeeScript 1.7.1
(function() {
  window.Brew.Agent = {
    setupTerrainAgent: function(game, level, mod_xy, monster_def_id, replacement_terrain_def_id) {
      var agent, terrain;
      terrain = level.getTerrainAt(mod_xy);
      agent = Brew.monsterFactory(monster_def_id, {
        terrain: terrain,
        replacement_terrain: Brew.terrainFactory(replacement_terrain_def_id)
      });
      level.setAgentAt(mod_xy, agent);
      game.scheduler.add(agent, true);
      return agent;
    },
    doAgentTurn: function(game, level, agent) {
      var agent_xy, is_blocked, m, new_xy, t, under_terrain;
      if ((agent.speed == null) || (agent.speed === 0)) {
        return false;
      }
      agent_xy = clone(agent.coordinates);
      new_xy = Brew.utils.forecastNextPoint(agent);
      t = level.getTerrainAt(new_xy);
      m = level.getMonsterAt(new_xy);
      if (new_xy == null) {
        console.error("unable to forecast move");
        return false;
      }
      is_blocked = (!level.checkValid(new_xy)) || (m != null) || (t.blocks_walking && t.blocks_flying);
      if (is_blocked) {
        console.log("crash!");
        agent.speed = 0;
        level.removeAgentAt(agent_xy);
        game.scheduler.remove(agent);
        if (agent.terrain.on_destroy != null) {
          under_terrain = agent.replacement_terrain;
          if (Brew.utils.isTerrain(under_terrain, "CHASM")) {
            level.setTerrainAt(agent_xy, under_terrain);
          } else {
            level.setTerrainAt(agent_xy, Brew.terrainFactory(agent.terrain.on_destroy));
          }
        }
        level.calcTerrainNavigation();
      } else {
        level.setTerrainAt(agent_xy, agent.replacement_terrain);
        level.removeAgentAt(agent_xy);
        agent.replacement_terrain = level.getTerrainAt(new_xy);
        level.setTerrainAt(new_xy, agent.terrain);
        level.setAgentAt(new_xy, agent);
        game.ui.drawMapAt(agent_xy);
        game.ui.drawMapAt(new_xy);
      }
      return true;
    },
    applyForceTo: function(agent, start_xy, towards_xy) {
      var theta;
      agent.speed = 1;
      theta = Brew.utils.calcAngle(start_xy, towards_xy);
      agent.origin_xy = agent.coordinates;
      return agent.angle = theta;
    },
    interactWithAgent: function(game, level, instigator, agent) {
      var away_xy, offset_xy, takesTurn;
      takesTurn = true;
      offset_xy = agent.coordinates.subtract(instigator.coordinates);
      away_xy = offset_xy.asUnit().multiply(5);
      this.applyForceTo(agent, agent.coordinates, agent.coordinates.add(away_xy));
      return takesTurn;
    },
    forceTerrain: function(game, level, forcer, terrain) {
      var force_xy, terrain_agent;
      game.msg("You smash into the " + terrain.name + ".");
      force_xy = terrain.coordinates;
      level.setTerrainAt(force_xy, Brew.terrainFactory(terrain.takes_force.force_terrain));
      game.ui.drawMapAt(force_xy);
      if (terrain.takes_force.force_agent != null) {
        terrain_agent = Brew.Agent.setupTerrainAgent(game, level, force_xy, "AGENT_TERRAIN_TRAVEL", terrain.takes_force.replace_terrain);
      }
      return true;
    }
  };

}).call(this);

//# sourceMappingURL=agent.map

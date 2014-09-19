class window.Brew.AbilityCode
	constructor: (@game) ->
		true

	gameLevel: () ->
		return @game.my_level

	gamePlayer: () ->
		return @game.my_player

	checkUseAt: (ability, map_xy) ->
		return @canUseAt(ability, map_xy)[0]

	checkPairUseAt: (ability, map_xy) ->
		# pull up ability definition from config
		ability_def = Brew.ability[ability]

		pair_ok = ability_def.pair
		return (@canUseAt(ability, map_xy)[0] and pair_ok)

	canUseAt: (ability, map_xy) ->
		[can_use, data] = switch ability
			when Brew.abilities.charge then @charge_canUseAt(map_xy)
			when Brew.abilities.fireball then @generic_canUseAt(ability, map_xy)
			when Brew.abilities.forcebolt then @generic_canUseAt(ability, map_xy)
			when Brew.abilities.entangle then @generic_canUseAt(ability, map_xy)
			when Brew.abilities.banish then @generic_canUseAt(ability, map_xy)
			when Brew.abilities.warcry then @generic_canUseAt(ability, map_xy)
			when Brew.abilities.defend then @generic_canUseAt(ability, map_xy)
			else
				console.error("invalid ability #{ability}")

		return [can_use, data]
	
	execute: (ability, map_xy, paired) ->
		# pull up ability definition from config
		ability_def = Brew.ability[ability]

		# if its sent to the other player, make sure its a pair ability
		if paired and (not ability_def.pair)
			@game.msg("#{ability_def.name} does not work across realms.")
			return false

		# check if we can use it
		[can_use, data] = @canUseAt(ability, map_xy)

		# if not, send error message
		if not can_use
			@game.msg(data)
			return false

		# send pair abilities to other screen/player
		if paired
			@game.socket.sendAbilityClick(
				@gamePlayer().coordinates, 
				@gamePlayer().active_ability, 
				map_xy
			)
			return true
			
		# otherwise continue on
		player = @gamePlayer()
		player_xy = player.coordinates

		# extract data
		xy = data.xy ? null
		target = data.target ? null

		endTurn = false # default

		endTurn = switch ability
			when Brew.abilities.charge then @charge_execute(player, player_xy, xy, target)
			when Brew.abilities.banish then @banish_execute(player, player_xy, xy, target)
			when Brew.abilities.warcry then @warcry_execute(player, player_xy, xy)
			when Brew.abilities.defend then @defend_execute(player, player_xy, xy)
			when Brew.abilities.fireball then @fireball_execute(player, player_xy, xy)
			when Brew.abilities.entangle then @entangle_execute(player, player_xy, xy)
			when Brew.abilities.forcebolt then @forcebolt_execute(player, player_xy, xy, target)

			else
				console.error("invalid executed ability #{ability}")

		cost = Brew.ability[ability].cost
		player.getStat(Brew.stat.stamina).deduct(cost)
		@game.ui.drawHudAll()

		if endTurn
			@game.endPlayerTurn()

	# ##################################################
	# ## effected tiles
	# ##################################################
	
	# getEffectedTiles: (ability, from_xy, to_xy) ->
	#	# EFFECT or AFFECT ?
	# 	tileList = switch ability
	# 		when Brew.abilities.fireball then to_xy.getSurrounding().merge(to_xy)
	# 		when Brew.abilities.entangle then to_xy.getSurrounding().merge(to_xy)
	# 		else [to_xy]

	##################################################
	## CHARGE
	##################################################

	charge_canUseAt: (map_xy) ->
		# pull up ability definition from config
		ability_def = Brew.ability[Brew.abilities.charge]

		# 1 - in range?
		dist2d = Brew.utils.dist2d(@gamePlayer().coordinates, map_xy)
		if dist2d > ability_def.range
			return [false, "Out of range"]

		# 2 - too close?
		if Math.floor(dist2d) <= 1
			return [false, "Too close"]

		# 3 - is there a target?
		target_mob = @gameLevel().getMonsterAt(map_xy)
		if not target_mob?
			return [false, "No target"]

		# 4 - check path
		line = Brew.utils.getLineBetweenPoints(@gamePlayer().coordinates, map_xy)
		last_xy = null
		actual_xy = null
		for xy, i in line
			# ignore starting point
			if i == 0
				last_xy = xy
				continue

			t = @gameLevel().getTerrainAt(xy)
			if t.blocks_walking
				return [false, "Something is in the way"]

			m = @gameLevel().getMonsterAt(xy)
			if m? and not Brew.utils.compareThing(m, target_mob)
				return [false, "Another target is in the way"]

			if m? and Brew.utils.compareThing(m, target_mob)
				actual_xy = last_xy
				break

			last_xy = xy

		if not actual_xy?
			return [false, "something horrible happened"]

		# 5- stamina
		has_stamina = true
		if not has_stamina
			return [false, "not enough stamina"]

		return [true, {
			"xy": actual_xy
			"target": target_mob
			}]

	charge_execute: (caster, from_xy, landing_xy, target_monster) ->
		traverse_lst = Brew.utils.getLineBetweenPoints(from_xy, landing_xy)
		projectile = Brew.featureFactory("PROJ_CHARGE", {code: caster.code, color: caster.color})
		@game.addAnimation(new Brew.ChargeAnimation(caster, projectile, traverse_lst, target_monster))
		return true

	##################################################
	## FIREBALL
	##################################################

	fireball_execute: (caster, from_xy, center_xy) ->
		traverse_lst = Brew.utils.getLineBetweenPoints(from_xy, center_xy)
		fireball_damage = Math.floor(caster.getStat(Brew.stat.stamina).getMax() / Brew.config.fireball_damage_div)
		fireball = Brew.featureFactory("PROJ_FIREBALL", {damage: fireball_damage})
		fireball.setFlag(Brew.flags.weapon_burning)
		@game.addAnimation(new Brew.FireballAnimation(caster, fireball, traverse_lst))
		return true 

	##################################################
	## FORCE BOLT
	##################################################

	forcebolt_execute: (caster, from_xy, center_xy, target) ->
		traverse_lst = Brew.utils.getLineBetweenPoints(from_xy, center_xy)
		bolt_damage = Math.floor(caster.getStat(Brew.stat.stamina).getMax() / Brew.config.forcebolt_damage_div)
		bolt = Brew.featureFactory("PROJ_FORCEBOLT", {damage: bolt_damage})
		bolt.code = Brew.utils.getLaserProjectileCode(from_xy, center_xy)
		@game.addAnimation(new Brew.LaserAnimation(caster, bolt, traverse_lst))
		return true 

	##################################################
	## BANISH
	##################################################

	banish_execute: (caster, from_xy, center_xy, target) ->
		if not target?
			console.error("no target for banish")
			return false

		if target.group == "TIME_MASTER"
			@game.msg("The Time Master laughs.")
			return false
		
		@game.msg("#{target.name} fades from your reality!")

		@game.socket.sendMonster(target)
		@gameLevel().removeMonsterAt(center_xy)
		@game.scheduler.remove(target)
		@game.ui.drawMapAt(center_xy)
		@game.addAnimation(new Brew.ShinyAnimation(center_xy, Brew.colors.violet))

		return true 

	##################################################
	## ENTANGLE
	##################################################

	entangle_execute: (caster, from_xy, center_xy) ->
		entangler = Brew.featureFactory("PROJ_ENTANGLE", {damage: 0})
		entangler.setFlag(Brew.flags.weapon_stun)
		
		impact_lst = center_xy.getSurrounding()
		impact_lst.push(center_xy)

		@game.addAnimation(new Brew.ImpactAnimation(impact_lst, entangler.color, caster, entangler))
		return true 

	##################################################
	## WAR DAMN CRY
	##################################################
	warcry_execute: (caster, from_xy, center_xy) ->
		# scare all nearby monsters - always fired from current player (even with allies)
		if not Brew.utils.compareThing(caster, @gamePlayer())
			message = "A terrifying war cry echos across reality"
		else
			message = "You roar a terrifying war cry!!"

		@game.msg(message)
		@game.addAnimation(new Brew.ShinyAnimation(@gamePlayer().coordinates, Brew.colors.hf_orange))

		for thing_id in @gamePlayer().knowledge
			m = @gameLevel().getMonsterById(thing_id)
			console.log(thing_id, m)
			if m?
				@game.setFlagWithCounter(m, Brew.flags.is_scared, 10)
				@game.ui.showDialogAbove(m.coordinates, Brew.Messages.getRandom("scared"))

		return true

	##################################################
	## DEFEND!
	##################################################
	defend_execute: (caster, from_xy, center_xy) ->
		# scare all nearby monsters - always fired from current player (even with allies)
		if not Brew.utils.compareThing(caster, @gamePlayer())
			message = "#{@game.pair.username} is defending you!"
		else
			message = "You take a moment to ready your defenses"

		@game.msg(message)
		@game.addAnimation(new Brew.ShinyAnimation(@gamePlayer().coordinates, Brew.colors.red))
		@game.setFlagWithCounter(@gamePlayer(), Brew.flags.defended, 10)

		return true

	##################################################
	## generic
	##################################################

	generic_canUseAt: (ability, map_xy) ->
		# pull up ability definition from config
		ability_def = Brew.ability[ability]

		# 1 - in range?
		dist2d = Brew.utils.dist2d(@gamePlayer().coordinates, map_xy)
		if dist2d > ability_def.range
			return [false, "Out of range"]

		# 2 - check path
		if ability_def.pathing
			line = Brew.utils.getLineBetweenPoints(@gamePlayer().coordinates, map_xy)
			last_xy = null
			actual_xy = null
			for xy, i in line
				# ignore starting point
				if i == 0
					last_xy = xy
					continue

				t = @gameLevel().getTerrainAt(xy)
				if t.blocks_flying
					return [false, "Something is in the way"]

				# got to last point, yay
				if i == (line.length - 1)
					last_xy = xy
					continue

				# monster in the way and not at the last point?
				m = @gameLevel().getMonsterAt(xy)
				if m?
					# actual_xy = xy
					# break
					return [false, "SomeTHING is in the way"]

				last_xy = xy

			if not actual_xy?
				# didn't hit anything, use the requested point
				actual_xy = map_xy

		# no pathing requireed, assume requested point
		else
			actual_xy = map_xy

		# 3 - check if we need a specific target
		target_mob = @gameLevel().getMonsterAt(map_xy)
		if ability_def.needs_target and not target_mob?
			return [false, "Target required"]

		# 4 - stamina
		has_stamina = @gamePlayer().getStat(Brew.stat.stamina).getCurrent() >= ability_def.cost
		if not has_stamina
			return [false, "not enough stamina"]

		data = {"xy": actual_xy}
		if ability_def.needs_target
			data.target = target_mob

		return [true, data]
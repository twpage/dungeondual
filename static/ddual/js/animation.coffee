class window.Brew.Animation extends Brew.Thing
	constructor: (animation_type) ->
		super "animation"
		@animationType = animation_type
		@turn = 0
		@active = true
		@over_saturate = false

	runTurn: (game, ui, level) ->
		@cleanup(game, ui, level)
		@turn += 1
		@update(game, ui, level)

	getSpeed: ->
		return 10000

class window.Brew.FlashAnimation extends Brew.Animation
	constructor: (@flash_xy, @flash_color) ->
		super "flash"
		@lastOverhead = null

	cleanup: (game, ui, level) ->
		if @turn == 1
			if @lastOverhead?
				level.setOverheadAt(@flash_xy, @lastOverhead)
			else
				level.removeOverheadAt(@flash_xy)

			ui.drawMapAt(@flash_xy)
			# game.finishAttack(@attacker, @defender, true, 0)

	update: (game, ui, level) ->
		if @turn == 1
			overhead = level.getOverheadAt(@flash_xy)

			if overhead?
				@lastOverhead = overhead

			flash = Brew.featureFactory("TILE_FLASH", {color: @flash_color})
			level.setOverheadAt(@flash_xy, flash)
			ui.drawMapAt(@flash_xy)
			# console.log("drawing flash at " + @flash_xy)

		else
			@active = false

class window.Brew.LaserAnimation extends Brew.Animation
	constructor: (@attacker, @projectile_thing, @full_path_lst) ->
		super "laser"
		@lastOverhead = null
		@over_saturate = true

	cleanup: (game, ui, level) ->
		# no cleanup on turn 0
		if @turn == 0
			return

		idx = @turn - 1
		if idx >= @full_path_lst.length
			console.log("tried to clean up bad index " + idx)
			return

		last_xy = @full_path_lst[idx]
		if @lastOverhead?
			level.setOverheadAt(last_xy, @lastOverhead)
		else
			level.removeOverheadAt(last_xy)

		ui.drawMapAt(last_xy)
		@lastOverhead = null

	update: (game, ui, level) ->
		# figure out where we are in the path list
		idx = @turn - 1
		# console.log(idx)
		# stop if we've gone over the whole path
		if idx == @full_path_lst.length
			console.log("error, index too high on pathing animation")
			@active = false
			return
		
		next_xy = @full_path_lst[idx]

		# stop when we hit the 'target'
		if idx == @full_path_lst.length - 1
			@active = false
			target = level.getMonsterAt(next_xy)
			# console.log("attacking target at " + next_xy)
			game.attack(@attacker, target, false, {remote: @projectile_thing})
		
		# otherwise keep drawing
		else
			overhead = level.getOverheadAt(next_xy)
			if overhead?
				@lastOverhead = overhead

			level.setOverheadAt(next_xy, @projectile_thing)
			ui.drawMapAt(next_xy)
			# console.log("drawing laser at " + next_xy)

class window.Brew.ThrownAnimation extends Brew.Animation
	constructor: (@thrower, @thrown_item, @full_path_lst) ->
		super "thrown"
		@lastOverhead = null

	cleanup: (game, ui, level) ->
		# no cleanup on turn 0
		if @turn == 0
			return

		idx = @turn - 1
		if idx >= @full_path_lst.length
			console.log("tried to clean up bad index " + idx)
			return

		last_xy = @full_path_lst[idx]
		if @lastOverhead?
			level.setOverheadAt(last_xy, @lastOverhead)
		else
			level.removeOverheadAt(last_xy)

		ui.drawMapAt(last_xy)
		@lastOverhead = null

	update: (game, ui, level) ->
		# figure out where we are in the path list
		idx = @turn - 1

		# stop if we've gone over the whole path
		if idx == @full_path_lst.length
			console.log("error, index too high on pathing animation")
			@active = false
			return
		
		next_xy = @full_path_lst[idx]

		# stop when we hit the 'target'
		if idx == @full_path_lst.length - 1
			@active = false
			level.setItemAt(next_xy, @thrown_item)
			# console.log("hitting target at " + next_xy)
			# game.attack(@attacker, target, false)
		
		# otherwise keep drawing
		else
			overhead = level.getOverheadAt(next_xy)
			if overhead?
				@lastOverhead = overhead

			level.setOverheadAt(next_xy, @thrown_item)
		
		ui.drawMapAt(next_xy)

class window.Brew.FireballAnimation extends Brew.Animation
	constructor: (@attacker, @rocket_item, @full_path_lst) ->
		super "fireball"
		@overhead_cache = {}
		@over_saturate = true
		@rocket_item.light_source = Brew.colors.orange
		@trail_feature = "PROJ_FIREBALL_TRAIL"

	cleanup: (game, ui, level) ->
		# no cleanup on turn 0
		if @turn == 0
			return

		idx = @turn - 1
		if idx >= @full_path_lst.length
			console.log("tried to clean up bad index " + idx)
			return

		last_xy = @full_path_lst[idx]
		level.setOverheadAt(last_xy, Brew.featureFactory(@trail_feature))

		ui.drawMapAt(last_xy)
		@lastOverhead = null

	update: (game, ui, level) ->
		# figure out where we are in the path list
		idx = @turn - 1

		# stop if we've gone over the whole path
		if idx == @full_path_lst.length
			console.log("error, index too high on pathing animation")
			@active = false
			return
		
		next_xy = @full_path_lst[idx]

		# stop when we hit the 'target'
		if idx == @full_path_lst.length - 1
			@active = false
			target = level.getMonsterAt(next_xy)

			# clean up smoke
			@replaceTrail(game, ui, level)
			@impact(game, ui, level, next_xy)
		
		# otherwise keep drawing
		else
			overhead = level.getOverheadAt(next_xy)
			@overhead_cache[next_xy.toKey()] = overhead

			level.setOverheadAt(next_xy, @rocket_item)
			ui.drawMapAt(next_xy)

	replaceTrail: (game, ui, level) ->
		for own key, cached_overhead of @overhead_cache
			xy = keyToCoord(key)
			if cached_overhead?
				level.setOverheadAt(xy, cached_overhead)
			else
				level.removeOverheadAt(xy)

	impact: (game, ui, level, center_xy) ->
		firey_lst = center_xy.getSurrounding()
		firey_lst.push(center_xy)
		firey_lst.reverse()

		impact_lst = []
		for xy in firey_lst
			t = level.getTerrainAt(xy)
			if t.blocks_walking
				continue
			impact_lst.push(xy)

		game.addAnimation(new Brew.ImpactAnimation(impact_lst, @rocket_item.color, @attacker, @rocket_item))

class window.Brew.ShinyAnimation extends Brew.Animation
	constructor: (@target, @shine_color) ->
		super "shiny"
		@oldcolor = @target.light_source
		@over_saturate = true

	cleanup: (game, ui, level) ->
		if @turn == 1
			@target.light_source = @oldcolor

	update: (game, ui, level) ->
		if @turn == 1
			@target.light_source = @shine_color


		else
			@active = false

class window.Brew.CircleAnimation extends Brew.Animation
	constructor: (@center_xy, @max_radius, @circle_color) ->
		super "circle"
		@overhead_cache = {}
		@over_saturate = false

	getPoints: (game, ui, level) ->
		circle_lst = Brew.utils.getCirclePoints(@center_xy, @turn)
		points_lst = []
		for xy in circle_lst
			if not level.checkValid(xy)
				continue

			t = level.getTerrainAt(xy)
			if t.blocks_walking and t.blocks_flying
				continue

			points_lst.push(xy)

		return points_lst

	cleanup: (game, ui, level) ->
		if @turn == 0
			return

		for xy in @getPoints(game, ui, level) # called before @turn +1
			cached_overhead = @overhead_cache[xy.toKey()]
			if cached_overhead?
				level.setOverheadAt(xy, cached_overhead)
			else
				level.removeOverheadAt(xy)

			ui.drawMapAt(xy)

	update: (game, ui, level) ->
		if @turn > @max_radius
			@active = false
			return

		for xy in @getPoints(game, ui, level) # called AFTER @turn +1
			# see if anything exists overhead
			existing_overhead = level.getOverheadAt(xy)
			
			if existing_overhead? and Brew.utils.compareDef(existing_overhead, "TILE_FLASH")
				continue

			else
				@overhead_cache[xy.toKey()] = existing_overhead # add null/undefined values too for later use
				flash = Brew.featureFactory("TILE_FLASH", {color: @circle_color})
				level.setOverheadAt(xy, flash)
				ui.drawMapAt(xy)

class window.Brew.ChargeAnimation extends Brew.Animation
	constructor: (@charger, @projectile_thing, @full_path_lst, @target) ->
		super "charge"
		@lastOverhead = null

	cleanup: (game, ui, level) ->
		# no cleanup on turn 0
		if @turn == 0
			return

		idx = @turn - 1
		if idx >= @full_path_lst.length
			console.log("tried to clean up bad index " + idx)
			return

		last_xy = @full_path_lst[idx]
		if @lastOverhead?
			level.setOverheadAt(last_xy, @lastOverhead)
		else
			level.removeOverheadAt(last_xy)

		ui.drawMapAt(last_xy)
		@lastOverhead = null

	update: (game, ui, level) ->
		# figure out where we are in the path list
		idx = @turn - 1

		# stop if we've gone over the whole path
		if idx == @full_path_lst.length
			console.log("error, index too high on pathing animation")
			@active = false
			return
		
		next_xy = @full_path_lst[idx]

		# stop when we hit the 'target'
		if idx == @full_path_lst.length - 1
			@active = false
			old_xy = clone(@charger.coordinates)
			level.removeMonsterAt(old_xy)
			level.setMonsterAt(next_xy, @charger)
			ui.drawMapAt(old_xy)
			game.attack(@charger, @target, true, {charge: true})
		
		# otherwise keep drawing
		else
			overhead = level.getOverheadAt(next_xy)
			if overhead?
				@lastOverhead = overhead

			level.setOverheadAt(next_xy, @projectile_thing)
		
		ui.drawMapAt(next_xy)

class window.Brew.ImpactAnimation extends Brew.Animation
	constructor: (@impact_xy_lst, @flash_color, @attacker, @weapon) ->
		super "flash"
		@overhead_cache = {}

	cleanup: (game, ui, level) ->
		if @turn == 1
			for xy in @impact_xy_lst
				cached_overhead = @overhead_cache[xy.toKey()]
				if cached_overhead?
					level.setOverheadAt(xy, cached_overhead)
				else
					level.removeOverheadAt(xy)

				ui.drawMapAt(xy)
				game.remoteImpact(@attacker, xy, @weapon)

	update: (game, ui, level) ->
		if @turn == 1
			for xy in @impact_xy_lst
				# see if anything exists overhead
				existing_overhead = level.getOverheadAt(xy)

				if existing_overhead? and Brew.utils.compareDef(existing_overhead, "TILE_FLASH")
					continue

				else
					@overhead_cache[xy.toKey()] = existing_overhead # add null/undefined values too for later use
					flash = Brew.featureFactory("TILE_FLASH", {color: @flash_color})
					level.setOverheadAt(xy, flash)
					ui.drawMapAt(xy)

		else
			@active = false

class window.Brew.ProjectileAnimation extends Brew.Animation
	constructor: (@attacker, @projectile_thing, @full_path_lst) ->
		super "projectile"
		@lastOverhead = null

	cleanup: (game, ui, level) ->
		# no cleanup on turn 0
		if @turn == 0
			return

		idx = @turn - 1
		if idx >= @full_path_lst.length
			console.log("tried to clean up bad index " + idx)
			return

		last_xy = @full_path_lst[idx]
		if @lastOverhead?
			level.setOverheadAt(last_xy, @lastOverhead)
		else
			level.removeOverheadAt(last_xy)

		ui.drawMapAt(last_xy)
		@lastOverhead = null

	update: (game, ui, level) ->
		# figure out where we are in the path list
		idx = @turn - 1
		# console.log(idx)
		# stop if we've gone over the whole path
		if idx == @full_path_lst.length
			console.log("error, index too high on pathing animation")
			@active = false
			return
		
		next_xy = @full_path_lst[idx]

		# stop when we hit the 'target'
		if idx == @full_path_lst.length - 1
			@active = false
			target = level.getMonsterAt(next_xy)
			# console.log("attacking target at " + next_xy)
			game.attack(@attacker, target, false, {remote: @projectile_thing})
		
		# otherwise keep drawing
		else
			overhead = level.getOverheadAt(next_xy)
			if overhead?
				@lastOverhead = overhead

			level.setOverheadAt(next_xy, @projectile_thing)
			ui.drawMapAt(next_xy)
			# console.log("drawing laser at " + next_xy)
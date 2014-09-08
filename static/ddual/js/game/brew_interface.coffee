class Brew.UserInterface
	constructor: (@game, display_info) ->
		# save displays object refs 
		@my_display = display_info["game"]
		@my_layer_display = display_info["layer"]
		@my_dialog_display = display_info["dialog"]
		@my_popup_display = display_info["popup"]

		@my_tile_width = @my_display.getContainer().width / Brew.config.screen_tiles_width
		@my_tile_height = @my_display.getContainer().height / Brew.config.screen_tiles_height

		@my_view = new Coordinate(0, 0)
		@input_handler = null
		@popup = {}
		@displayat = {}
		@highlights = {}

		@debug =
			fov: {}
			pathmaps: {}

		# wait a bit to initialize the layer display
		setTimeout(=> 
			@initLayerDisplay()
			@initDialogDisplay()
		, 30)

	gameLevel: () ->
		return @game.my_level

	gamePlayer: () ->
		return @game.my_player

	keypress: (e) ->
		ui_keycode = e.keyCode 
		shift_key = e.shiftKey

		if @game.hasAnimations()
			console.log("ignoring input while animations finish their thing")
			
		else

			if not @input_handler
				@inputGameplay(ui_keycode, shift_key)
			else if @input_handler == "inventory"
				@inputInventory(ui_keycode)
			else if @input_handler == "item_menu"
				@inputItemMenu(ui_keycode)
			else if @input_handler == "popup_to_dismiss"
				@inputPopupToDismiss(ui_keycode)
			else if @input_handler == "chat"
				@inputChat(ui_keycode, shift_key)
			else if @input_handler == "abilities"
				@inputAbilities(ui_keycode, shift_key)
			else if @input_handler == "died"
				@inputDied(ui_keycode, shift_key)
			else if @input_handler == "victory"
				@inputVictory(ui_keycode, shift_key)


	# ------------------------------------------------------------
	# Drawing
	# ------------------------------------------------------------

	centerViewOnPlayer: () ->
		if @gameLevel().width <= @my_display.width and @gameLevel().height <= @my_display.height
			return
			
		half_x = (@my_display.getOptions().width / 2)
		half_y = (@my_display.getOptions().height / 2)
		
		view_x = Math.min(Math.max(0, @gamePlayer().coordinates.x - half_x), @gameLevel().width - @my_display.getOptions().width)
		view_y = Math.min(Math.max(0, @gamePlayer().coordinates.y - half_y), @gameLevel().height - @my_display.getOptions().height)
		
		@my_view = new Coordinate(view_x, view_y)
		
	drawDisplayAll: (options) ->
		@clearLayerDisplay()
		for row_y in [0..@my_display.getOptions().height-1]
			for col_x in [0..@my_display.getOptions().width-1]
				screen_xy = new Coordinate(col_x, row_y)
				@drawDisplayAt(screen_xy, null, options)

	drawMapAt: (map_xy, options) ->
		screen_xy = map_xy.subtract(@my_view)
		@drawDisplayAt(screen_xy, map_xy, options)
		
	drawDisplayAt: (xy, map_xy, options) ->
		options ?= {}
		color_mod = options?.color_mod ? [0, 0, 0]
		over_saturate = options?.over_saturate ? false

		if not map_xy?
			map_xy = xy.add(@my_view)
		
		if not @gameLevel().checkValid(map_xy)
			console.log(map_xy)
			return
			
		# debug: draw pathmaps
		if @debug.pathmaps.index?
			[map_title, pathmap] = @debug.pathmaps.list[@debug.pathmaps.index]
			map_val = pathmap[map_xy.toKey()]
			
			if map_val == MAX_INT
				return
			else if map_val < 0
				c = Math.round(255 * (map_val / pathmap.min_value), 0)
			else
				c = Math.round(255 * (1 - (map_val / pathmap.max_value)), 0)

			r = if map_val == 0 then 255 else 0
			
			@my_display.draw(xy.x, xy.y, " ", 'black', ROT.Color.toHex([r, c, c]))
			return
			
		in_view = @gamePlayer().canView(map_xy)
		lighted = @gameLevel().getLightAt(map_xy)

		# debug: show monster views
		if @debug.fov.monster?
			in_view = @debug.fov.monster.canView(map_xy)
			lighted = Brew.colors.light_blue
		
		memory = @gamePlayer().getMemoryAt(@gameLevel().id, map_xy)
		terrain = @gameLevel().getTerrainAt(map_xy)
		feature = @gameLevel().getFeatureAt(map_xy)
		overhead = @gameLevel().getOverheadAt(map_xy)
		fromMemory = false

		draw = []
		prelighting_draw = [null, null, null]
		is_lit = lighted? or (@debug_monster_fov == true)
		can_view_and_lit = (in_view and is_lit) or map_xy.compare(@gamePlayer().coordinates)
		

		@clearDisplayAt(@my_layer_display, xy)

		# not in FOV, or in FOV but not sufficiently lit
		if not can_view_and_lit
			
			if not memory?
				draw = [" ", Brew.colors.black, Brew.colors.black]

			else
				fromMemory = true
				draw = [memory.code, Brew.colors.memory, Brew.colors.memory_bg]
			
		# in FOV and lit
		else
			
			if not terrain?
				debugger
				
			item = @gameLevel().getItemAt(map_xy)
			monster = @gameLevel().getMonsterAt(map_xy)
			
			if monster?
				@gamePlayer().setMemoryAt(@gameLevel().id, map_xy, terrain)  # remember what the monster was standing on

				if monster.hasFlag(Brew.flags.on_fire)
					mob_color = Brew.colors.hf_orange
				else if monster.hasFlag(Brew.flags.stunned)
					mob_color = Brew.colors.light_blue
				else if monster.hasFlag(Brew.flags.poisoned)
					mob_color = Brew.colors.dark_green
				else
					mob_color = terrain.bgcolor
				draw = [monster.code, monster.color, mob_color]

			else if item?
				@gamePlayer().setMemoryAt(@gameLevel().id, map_xy, item)
				draw = [item.code, item.color, terrain.bgcolor]
				
			else
				@gamePlayer().setMemoryAt(@gameLevel().id, map_xy, terrain)
				draw = [terrain.code, terrain.color, terrain.bgcolor]
				
				# combine terrain and features that modify terrain
				if feature? and feature.code?
					draw[0] = feature.code

				if feature? and feature.color?
					draw[1] = feature.getColor()

			# overtop layer features
			if overhead?
				@my_layer_display.draw(xy.x, xy.y, overhead.code, ROT.Color.toHex(overhead.color))

			# apply lighting
			prelighting_draw = draw[..]
			if over_saturate
				draw[1] = ROT.Color.multiply(lighted, draw[1])
				draw[2] = ROT.Color.multiply(lighted, draw[2])
			else
				draw[1] = Brew.utils.minColorRGB(ROT.Color.multiply(lighted, draw[1]), draw[1])
				draw[2] = Brew.utils.minColorRGB(ROT.Color.multiply(lighted, draw[2]), draw[2])

		# apply override (when map is shown behind inventory screen, etc)
		if options?.color_override?
			draw[1] = options.color_override
			draw[2] = Brew.colors.black
			
		h = @highlights[map_xy.toKey()]
		if h?
			draw[2] = h
		# # is monster current target? change background color
		# if monster? and @firetarget.id? and monster.id == @firetarget.id and not monster.is_dead
		# 	draw[2] = ROT.Color.add(draw[2], [0, 50, 0])

		@my_display.draw(xy.x, xy.y, draw[0], ROT.Color.toHex(draw[1]), ROT.Color.toHex(draw[2]))
		if not options?.color_override?
			@displayat[map_xy.toKey()] = draw


	updatePairDisplay: (drawings) ->
		# console.log("updating pair display UI")

		shade_color = Brew.colors.pair_shade

		for own key, draw_array of drawings
			xy = keyToCoord(key)
			code = draw_array[0]
			color = ROT.Color.toHex(ROT.Color.interpolate(draw_array[1], shade_color, 0.5))
			bgcolor = ROT.Color.toHex(ROT.Color.interpolate(draw_array[2], shade_color, 0.5))

			@my_pair_display.draw(xy.x, xy.y, code, color, bgcolor)

		@drawings = drawings
		return true

	updatePairDisplayAt: (xy) ->
		# use cached drawings to redraw pair screen

		shade_color = Brew.colors.pair_shade

		key = xy.toKey()
		draw_array = @drawings[key]
		code = draw_array[0]
		color = ROT.Color.toHex(ROT.Color.interpolate(draw_array[1], shade_color, 0.5))
		bgcolor = ROT.Color.toHex(ROT.Color.interpolate(draw_array[2], shade_color, 0.5))

		@my_pair_display.draw(xy.x, xy.y, code, color, bgcolor)
		return true

	# ------------------------------------------------------------
	# draw HUD
	# ------------------------------------------------------------

	drawHudAll: () ->
		# redraw the HUD
		player = @gamePlayer()
		player.hero_type = "Squire"
		desc = "#{player.name} <#{player.hero_type}>"
		@my_hud_display.drawText(0, 0, player.name)
		
		# health
		row_start = 1
		maxhp = player.getStat(Brew.stat.health).getMax()
		hp = player.getStat(Brew.stat.health).getCurrent()
		for i in [1..maxhp]
			color = if (i <= hp) then Brew.colors.red else Brew.colors.normal
			@my_hud_display.draw(i-1, row_start, Brew.unicode.heart, ROT.Color.toHex(color))

		# stamina
		@drawHudBar(0, 2, 18, 
			player.getStat(Brew.stat.stamina).getCurrent(), 
			player.getStat(Brew.stat.stamina).getMax(),
			Brew.colors.violet
		)

		@drawHudSync()
		@drawHudAbility()

	drawHudAbility: () ->
		black_hex = ROT.Color.toHex(Brew.colors.black)
		player = @gamePlayer()
		if player.active_ability?
			abil_hotkey = player.abilities.indexOf(player.active_ability) + 1
			abil_desc = "Using #{Brew.ability[player.active_ability].name.toUpperCase()} (#{abil_hotkey})"
		else
			abil_desc = "No ability selected"
		
		start_x = Math.floor(Brew.config.screen_tiles_width / 2)
		max_width = Math.floor(Brew.config.screen_tiles_width / 2)

		num_spaces = max_width - abil_desc.length
		spaces = ("_" for i in [0..num_spaces-1]).join("")
		@my_hud_display.drawText(start_x, 0, "%c{#{black_hex}}#{spaces}%c{white}#{abil_desc}")


	drawHudSync: () ->
		# draw the sync status

		black_hex = ROT.Color.toHex(Brew.colors.black)

		if not @game.is_paired
			status_msg = "Not Connected"
			message = "No Data"
		else if @game.is_paired and not @game.pair.sync
			status_msg = "Connected"
			message = "Awaiting Sync"
		else
			status_msg = if @game.pair.sync.status then "In Sync" else "Out of Sync"
			message = @game.pair.sync.message

		start_x = Math.floor(Brew.config.screen_tiles_width / 2)
		max_width = Math.floor(Brew.config.screen_tiles_width / 2)

		num_spaces = max_width - status_msg.length
		spaces = ("_" for i in [0..num_spaces-1]).join("")
		@my_hud_display.drawText(start_x, 1, "%c{#{black_hex}}#{spaces}%c{white}#{status_msg}")

		num_spaces = max_width - message.length
		spaces = ("_" for i in [0..num_spaces-1]).join("")
		@my_hud_display.drawText(start_x, 2, "%c{#{black_hex}}#{spaces}%c{white}#{message}")

	drawHudBar: (start_x, start_y, max_tiles, current_amount, max_amount, full_color) ->
		black_hex = ROT.Color.toHex(Brew.colors.black)

		raw_num_bars = Math.min(1.0, current_amount / max_amount) * max_tiles
		num_bars = Math.ceil(raw_num_bars)
		remainder = num_bars - raw_num_bars
		tile = null

		for i in [0..max_tiles-1]
			if i == num_bars - 1
				if remainder < 0.25
					fadecolor = full_color
				else if remainder < 0.5
					fadecolor = ROT.Color.interpolate(full_color, Brew.colors.normal, 0.25)
				else if remainder < 0.75
					fadecolor = ROT.Color.interpolate(full_color, Brew.colors.normal, 0.5)
				else
					fadecolor = ROT.Color.interpolate(full_color, Brew.colors.normal, 0.75)

				@my_hud_display.draw(start_x + i, start_y, " ", "white", ROT.Color.toHex(full_color))

			else if i < num_bars
				@my_hud_display.draw(start_x + i, start_y, " ", "white", ROT.Color.toHex(full_color))

			else
				@my_hud_display.draw(start_x + i, start_y, " ", "white", ROT.Color.toHex(Brew.colors.normal))

		violet_rgb = ROT.Color.toHex(full_color)
		@my_hud_display.drawText(start_x + max_tiles + 1, start_y, "%c{#{violet_rgb}}#{current_amount}%c{#{black_hex}}_")

	drawMessage: (message) ->
		black_hex = ROT.Color.toHex(Brew.colors.black)

		max_length = Brew.config.screen_tiles_width - 1
		num_spaces = max_length - message.length
		spaces = ("_" for i in [0..num_spaces]).join("")

		x = 0
		y = 3 * @my_tile_height
		# @my_hud_display._backend._context.clearRect(x, y, @my_tile_width * max_length, @my_tile_height)
		@my_hud_display.drawText(0, 3, message+"%c{#{black_hex}}#{spaces}")

	drawFooter: (look_xy) ->
		black_hex = ROT.Color.toHex(Brew.colors.black)
		in_view = @gamePlayer().canView(look_xy)
		lighted = @gameLevel().getLightAt(look_xy)

		t = @gameLevel().getTerrainAt(look_xy)
		f = @gameLevel().getFeatureAt(look_xy)
		i = @gameLevel().getItemAt(look_xy)
		m = @gameLevel().getMonsterAt(look_xy)
		memory = @gamePlayer().getMemoryAt(@gameLevel().id, look_xy)

		is_lit = lighted?
		can_view_and_lit = (in_view and is_lit) or look_xy.compare(@gamePlayer().coordinates)

		if not can_view_and_lit
			if memory?
				tap = if memory.objtye == "item" then "a #{memory.name}" else memory.name
				message = "You remember seeing #{tap} there"
			else
				message = "You don't see anything"
		else
			if m? and Brew.utils.compareThing(m, @gamePlayer())
				message = "You are standing on #{t.name}"
			else if m?
				message = "#{m.name}"

			else if i?
				message = "You see a #{@game.getItemNameFromCatalog(i)}"

			else
				message = "You see #{t.name}"

		max_length = Brew.config.screen_tiles_width - 1
		num_spaces = max_length - message.length
		spaces = ("_" for i in [0..num_spaces]).join("")

		@my_footer_display.drawText(0, 0, message+"%c{#{black_hex}}#{spaces}")

	# ------------------------------------------------------------
	# generic display code pop-up menus and layers
	# ------------------------------------------------------------

	drawBorders: (display, color, rectangle) ->
		rectangle ?= {}

		hex_color = ROT.Color.toHex(color)
		
		h = rectangle.height ? (Brew.config.screen_tiles_height - 1)
		w = rectangle.width ? (Brew.config.screen_tiles_width - 1)
		x = rectangle.x ? 0
		y = rectangle.y ? 0

		for row_y in [y..y+h]
			display.draw(x, row_y, "|", hex_color)
			display.draw(x+w, row_y, "|", hex_color)
			
		for col_x in [x..x+w]
			display.draw(col_x, y, Brew.unicode.horizontal_line, hex_color)
			display.draw(col_x, y+h, Brew.unicode.horizontal_line, hex_color)
			
		display.draw(x, y, Brew.unicode.corner_topleft, hex_color)
		display.draw(x, y+h, Brew.unicode.corner_bottomleft, hex_color)
		display.draw(x+w, y, Brew.unicode.corner_topright, hex_color)
		display.draw(x+w, y+h, Brew.unicode.corner_bottomright, hex_color)

	clearDisplay: (display) ->
		# rot.js should have a way to do this :(
		display._backend._context.clearRect(0, 0, display.getContainer().width, display.getContainer().height)

	clearPopupDisplay: ->
		@clearDisplay(@my_popup_display)

	clearLayerDisplay: ->
		@clearDisplay(@my_layer_display)
	
	clearDialogDisplay: ->
		@clearDisplay(@my_dialog_display)

	clearDisplayAt: (display, xy) ->
		# rot.js should have a way to do this :(
		x = xy.x * @my_tile_width
		y = xy.y * @my_tile_height
		display._backend._context.clearRect(x, y, @my_tile_width, @my_tile_height)

	initLayerDisplay: () ->
		pos = $(@my_display.getContainer()).position()
		
		$("#id_div_layer").css({
			position: "absolute",
			top: pos.top,
			left: pos.left
		})
		
		@clearLayerDisplay()
		$("#id_div_layer").show()

	initDialogDisplay: () ->
		pos = $(@my_display.getContainer()).position()
		
		$("#id_div_dialog").css({
			position: "absolute",
			top: pos.top,
			left: pos.left
		})
		
		@clearDialogDisplay()
		$("#id_div_dialog").show()

	showInfoScreen: (width_tiles, height_tiles) ->
		# dim the screen background
		@drawDisplayAll({ color_override: [50, 50, 50]})

		# reset popup div location todo: slide it out
		pos = $(@my_display.getContainer()).position()
		
		# figure out where to center the pop up
		isCentered = true

		offset_width_tiles = Math.floor((Brew.config.screen_tiles_width - width_tiles) / 2)
		offset_height_tiles = Math.floor((Brew.config.screen_tiles_height - height_tiles) / 2)

		$("#id_div_popup").css({
			position: "absolute",
			top: pos.top
			left: pos.left
		})

		# $("#id_div_popup").attr("width", offset_width_tiles * @my_tile_width)
		# $("#id_div_popup").attr("height", offset_height_tiles * @my_tile_height)

		@clearPopupDisplay()

		@drawBorders(@my_popup_display, Brew.colors.white, 
		{
			x: offset_width_tiles
			y: offset_height_tiles
			width: width_tiles
			height: height_tiles
		})
		
		$("#id_div_popup").show()


		@my_popup_display.drawText(offset_width_tiles + 1, offset_height_tiles + 1, @game.getItemNameFromCatalog(@popup.item))

		@my_popup_display.drawText(offset_width_tiles + 1, offset_height_tiles + 3, @popup.item.description, width_tiles - 1)

		@input_handler = "popup_to_dismiss"

	showInventory: ->
		# dim the screen background
		@drawDisplayAll({ color_override: [50, 50, 50]})
		
		# reset popup div location todo: slide it out
		pos = $(@my_display.getContainer()).position()
		
		$("#id_div_popup").css({
			position: "absolute",
			top: pos.top,
			left: pos.left
		})
		
		@clearPopupDisplay()

		color_title_hex = ROT.Color.toHex(Brew.colors.inventorymenu.title)
		color_text_hex = ROT.Color.toHex(Brew.colors.inventorymenu.text)
		color_hotkey_hex = ROT.Color.toHex(Brew.colors.inventorymenu.hotkey)

		@drawBorders(@my_popup_display, Brew.colors.inventorymenu.border)
		$("#id_div_popup").show()
		
		# draw inventory
		if @popup.context
			action_word = if @popup.context == "apply" then "use" else @popup.context
			context = action_word[0].toUpperCase() + action_word[1..]
			inventory_title = context + " what?"
		else
			inventory_title = "Ye Inventory"
		
		# filter out items out of context
		filter_fn = switch @popup.context
			when "apply" then (i) => @game.canApply(i)
			when "remove" then (i) => @game.canRemove(i)
			when "equip" then (i) => @game.canEquip(i)
			when "drop" then (i) => @game.canDrop(i)
			when "give" then (i) => @game.canGive(i)
			when "throw" then (i) => false
			else (i) => true

		@my_popup_display.drawText(1, 1, "%c{#{color_title_hex}}" + inventory_title)
		y = 2
		for own key, item of @gamePlayer().inventory.items
			if not filter_fn(item) then continue
			
			# lower_key = String.fromCharCode(key.charCodeAt(0)+32) # i think lowercase loosk better
			@my_popup_display.draw(1, y, item.inv_key_lower, color_hotkey_hex)
			@my_popup_display.draw(3, y, item.code, ROT.Color.toHex(item.color))
			
			text = "%c{#{color_text_hex}}" + @game.getItemNameFromCatalog(item)
			if item.equip
				text += " (Equipped)"
			@my_popup_display.drawText(5, y, text)
			y += 1
		
		if @popup.context == "apply"
			apply_list = @game.getApplicableTerrain(@gamePlayer())
			@popup.terrain = {}
			y += 2
			for apply in apply_list
				offset_xy = apply[0]
				terrain = apply[1]
				
				## add link to the terrain so the inv menu can pick it up
				offset_info = Brew.utils.getOffsetInfo(offset_xy)
				@popup.terrain[offset_info.arrow_keycode] = terrain
				# @popup.terrain[offset_info.numpad_keycode] = terrain
				# @popup.terrain[offset_info.wasd_keycode] = terrain
				
				## draw the terrain
				@my_popup_display.draw(1, y, offset_info.unicode, ROT.Color.toHex(Brew.colors.white))
				@my_popup_display.draw(3, y, terrain.code, ROT.Color.toHex(terrain.color))
				text = "%c{#{color_text_hex}}" + terrain.name
				@my_popup_display.drawText(5, y, text)
				y += 1
			
		@popup.inventory = @gamePlayer().inventory
		@input_handler = "inventory"

	showItemMenu: (item) ->
		# travel from inventory menu to item menu
		@clearPopupDisplay()
		
		color_title_hex = ROT.Color.toHex(Brew.colors.itemmenu.title)
		color_text_hex = ROT.Color.toHex(Brew.colors.itemmenu.text)
		color_hotkey_hex = ROT.Color.toHex(Brew.colors.itemmenu.hotkey)

		@drawBorders(@my_popup_display, Brew.colors.itemmenu.border)
		@my_popup_display.drawText(1, 1, "%c{#{color_title_hex}}"+ @game.getItemNameFromCatalog(item))

		@my_popup_display.drawText(1, 3, "%c{#{color_title_hex}}"+ @game.getItemDescription(item), 38)
		
		
		extra_desc = ""
		if item.group == Brew.groups.WEAPON
			extra_desc = "Damage: #{item.damage}"
		else if item.group == Brew.groups.ARMOR
			extra_desc = "Block: #{item.block}"
		else if item.group == Brew.groups.HAT
			extra_desc = "Hats are just decorative for now"

		@my_popup_display.drawText(1, 8, extra_desc, 38)

		actions =
			apply: @game.canApply(item)
			equip: @game.canEquip(item)
			remove: @game.canRemove(item)
			drop: true
			throw: false
			give: true
		
		i = 0
		for own action, can_do_it of actions
			if can_do_it
				action_name = if action == "apply" then "use" else action
				@my_popup_display.drawText(2, 10+i, "%c{#{color_hotkey_hex}}" + action_name[0].toUpperCase() + "%c{#{color_text_hex}}" + action_name[1..])
				i += 1
		
		@popup.item = item
		@popup.actions = actions
		@input_handler = "item_menu"

	showChat: () ->
		# dim the screen background
		@drawDisplayAll({ color_override: [50, 50, 50]})

		# reset popup div location todo: slide it out
		pos = $(@my_display.getContainer()).position()
		
		$("#id_div_popup").css({
			position: "absolute",
			top: pos.top
			left: pos.left
		})

		@clearPopupDisplay()

		@drawBorders(@my_popup_display, Brew.colors.white, 
		{
			x: 0
			y: 0
			width: Brew.config.screen_tiles_width - 1
			height: 4
		})
		
		$("#id_div_popup").show()

		@my_popup_display.drawText(1, 1, "Say what? <use delete to erase>")
		@my_popup_display.drawText(1, 2, "%c{cyan}#{@popup.text}")
		@my_popup_display.drawText(1, 4, "ENTER sends - press ESCAPE to cancel")

		@input_handler = "chat"

	showDied: () ->
		# dim the screen background
		@drawDisplayAll({ color_override: [50, 50, 50]})

		# reset popup div location todo: slide it out
		pos = $(@my_display.getContainer()).position()
		
		$("#id_div_popup").css({
			position: "absolute",
			top: pos.top
			left: pos.left
		})

		@clearPopupDisplay()

		@drawBorders(@my_popup_display, Brew.colors.white, 
		{
			x: 0
			y: 0
			width: Brew.config.screen_tiles_width - 1
			height: 4
		})
		
		$("#id_div_popup").show()

		@my_popup_display.drawText(1, 1, "Congratulations, you have died!")
		@my_popup_display.drawText(1, 2, "Press ENTER to start a new game")
		@my_popup_display.drawText(1, 3, "Press ESC to return to the menu")

		@input_handler = "died"

	showVictory: () ->
		# dim the screen background
		@drawDisplayAll({ color_override: [50, 50, 50]})

		# reset popup div location todo: slide it out
		pos = $(@my_display.getContainer()).position()
		
		$("#id_div_popup").css({
			position: "absolute",
			top: pos.top
			left: pos.left
		})

		@clearPopupDisplay()

		@drawBorders(@my_popup_display, Brew.colors.white, 
		{
			x: 0
			y: 0
			width: Brew.config.screen_tiles_width - 1
			height: 12
		})
		
		$("#id_div_popup").show()

		@my_popup_display.drawText(1, 1, "Congratulations, you defeated the Time Master")
		@my_popup_display.drawText(1, 2, "and saved the realm.")
		@my_popup_display.drawText(1, 4, "I really wish I had a better victory screen for you, but it is day 7 and 4 hours to go so this is all you get! Oh, and a database entry! Thanks for playing!", 38)

		@my_popup_display.drawText(1, 10, "Press ENTER to start a new game")
		@my_popup_display.drawText(1, 11, "Press ESC to return to the menu")

		@input_handler = "died"

	showHelp: () ->
		black_hex = ROT.Color.toHex(Brew.colors.black)
		# dim the screen background
		@drawDisplayAll({ color_override: [50, 50, 50]})

		# reset popup div location todo: slide it out
		pos = $(@my_display.getContainer()).position()
		
		$("#id_div_popup").css({
			position: "absolute",
			top: pos.top
			left: pos.left
		})

		@clearPopupDisplay()

		@drawBorders(@my_popup_display, Brew.colors.white, 
		{
			x: 0
			y: 0
			width: Brew.config.screen_tiles_width - 1
			height: Brew.config.screen_tiles_height - 1
		})
		
		$("#id_div_popup").show()

		@my_popup_display.drawText(1, 1, Brew.helptext, 40)
		@input_handler = "popup_to_dismiss"

	showMonsterInfo: () ->
		black_hex = ROT.Color.toHex(Brew.colors.black)
		# dim the screen background
		@drawDisplayAll({ color_override: [50, 50, 50]})

		# reset popup div location todo: slide it out
		pos = $(@my_display.getContainer()).position()
		
		$("#id_div_popup").css({
			position: "absolute",
			top: pos.top
			left: pos.left
		})

		@clearPopupDisplay()

		@drawBorders(@my_popup_display, Brew.colors.white, 
		{
			x: 0
			y: 0
			width: Brew.config.screen_tiles_width - 1
			height: Brew.config.screen_tiles_height - 1
		})
		
		$("#id_div_popup").show()

		@my_popup_display.drawText(1, 1, @popup.monster.name, 38)

		desc = if @popup.monster.description? then @popup.monster.description else "No description"
		@my_popup_display.drawText(1, 3, desc, 38)


		i = 0
		for flag in @popup.monster.getFlags()
			desc = Brew.flagDesc[flag]
			@my_popup_display.drawText(1, 8+i, desc, 38)
			i += 1

		@input_handler = "popup_to_dismiss"


	showTimeOrbScreen: () ->
		# use the magical time orb to send abilities / items
		@clearPopupDisplay()
		
		color_title_hex = ROT.Color.toHex(Brew.colors.itemmenu.title)
		color_text_hex = ROT.Color.toHex(Brew.colors.itemmenu.text)
		color_hotkey_hex = ROT.Color.toHex(Brew.colors.itemmenu.hotkey)
		## todo: new menu color for time orb
		@drawBorders(@my_popup_display, Brew.colors.itemmenu.border)

		$("#id_div_popup").show()
		
		@my_popup_display.drawText(2, 1, "The TIME ORB pulses and swirls")
		@my_popup_display.drawText(2, 2, "mysteriously.")
		@my_popup_display.drawText(2, 4, "You can use it to help your partner")
		@my_popup_display.drawText(2, 5, "across the splintered reality within")
		@my_popup_display.drawText(2, 6, "the Caves:")

		row_start = 8
		@my_popup_display.drawText(2, row_start, "- Incoming -")
		@my_popup_display.drawText(2, row_start+1, "(1) Fireball")

		row_start += 2
		@my_popup_display.drawText(2, row_start, "- Send -")
		@my_popup_display.drawText(2, row_start+1, "(!) Send Item")
		@my_popup_display.drawText(2, row_start+2, "(@) Send Monster")

		@input_handler = "timeorb"

	showAbilities: () ->
		# dim the screen background
		@drawDisplayAll({ color_override: [50, 50, 50]})
		
		# reset popup div location todo: slide it out
		pos = $(@my_display.getContainer()).position()
		
		$("#id_div_popup").css({
			position: "absolute",
			top: pos.top,
			left: pos.left
		})
		
		@clearPopupDisplay()

		color_title_hex = ROT.Color.toHex(Brew.colors.itemmenu.title)
		color_text_hex = ROT.Color.toHex(Brew.colors.itemmenu.text)
		color_hotkey_hex = ROT.Color.toHex(Brew.colors.itemmenu.hotkey)
		## todo: new menu color for abilities
		@drawBorders(@my_popup_display, Brew.colors.itemmenu.border)

		$("#id_div_popup").show()
		
		@my_popup_display.drawText(2, 1, "Abilities and Spells")
		row_start = 3

		for abil, idx in @gamePlayer().getAbilities()
			@my_popup_display.drawText(2, row_start+idx, "(#{idx+1}) #{Brew.ability[abil].name}")
			@my_popup_display.drawText(2, row_start+idx+1, "#{Brew.ability[abil].description}")
			@my_popup_display.drawText(2, row_start+idx+2, if Brew.ability[abil].pair then "Can be used to help allies" else "")

			row_start += 3



		@input_handler = "abilities"

	# ------------------------------------------------------------
	# keyboard input
	# ------------------------------------------------------------

	inputGameplay: (keycode, shift_key) ->

		# LEFT: left arrow + a
		if keycode in Brew.keymap.MOVE_LEFT
			offset_xy = Brew.directions.w # new Coordinate(-1, 0)
			@game.movePlayer(offset_xy)

		# RIGHT: right arrow + d
		else if keycode in Brew.keymap.MOVE_RIGHT
			offset_xy = Brew.directions.e # new Coordinate(1, 0)
			@game.movePlayer(offset_xy)

		# UP: up arrow + w
		else if keycode in Brew.keymap.MOVE_UP
			offset_xy = Brew.directions.n # new Coordinate(0, -1)
			@game.movePlayer(offset_xy)

		# DOWN: down arrow + s
		else if keycode in Brew.keymap.MOVE_DOWN
			offset_xy = Brew.directions.s # new Coordinate(0, 1)
			@game.movePlayer(offset_xy)
			
		# DO ACTION: space, NUMPAD 0
		else if keycode in Brew.keymap.GENERIC_ACTION
			@game.doPlayerAction()
			
		# # d : drop
		# else if keycode == 68
		# 	@popup.context = "drop"
		# 	@showInventory()
		
		# # e : equip
		# else if keycode == 69
		# 	@popup.context = "equip"
		# 	@showInventory()

		# # r : remove
		# else if keycode == 82
		# 	@popup.context = "remove"
		# 	@showInventory()
			
		# # a : apply / arm / activate
		# else if keycode == 65
		# 	@popup.context = "apply"
		# 	@showInventory()
			
		# # t : throw
		# else if keycode == 84
		# 	@popup.context = "throw"
		# 	@showInventory()
			
		# t : talk
		else if keycode in Brew.keymap.TALK
			@popup.context = "chat"
			@popup.text = ""
			@showChat()

		# u : use
		else if keycode in Brew.keymap.USE
			@popup.context = "apply"
			@showInventory()

		# i : inv
		else if keycode in Brew.keymap.INVENTORY
			@showInventory()
			
		# # q : toggle pathmaps debug
		# else if keycode == 81
		# 	@debugPathMaps()
		
		# # / : toggle FOV debug
		# else if keycode == 191 
		# 	@debugMonsterFov()

		# z : abilitieZ
		else if keycode in Brew.keymap.SHOW_ABILITIES
			@showAbilities()

		# else if keycode == 191 # / ? help
		else if keycode in Brew.keymap.HELP
			@showHelp()

		# else if keycode == 192 ## back tick `
		else if keycode in Brew.keymap.DEBUG
			@debugAtCoords()

		# 1 - 6
		# else if keycode in [49, 50, 51, 52, 53, 54]
		else if keycode in Brew.keymap.ABILITY_HOTKEY
			@game.doPlayerSelectAbility(keycode)

	inputAbilities: (keycode) ->
		# 1 - 6
		if keycode in [49, 50, 51, 52, 53, 54]
			@game.doPlayerSelectAbility(keycode)

		$("#id_div_popup").hide()
		@drawDisplayAll()
		@popup = {}
		@input_handler = null

	inputInventory: (keycode) ->	
		# first check apply terrain
		if @popup.terrain? and keycode of @popup.terrain
			@game.doPlayerApplyTerrain(@popup.terrain[keycode], false)
			
		# now check items
		inv_key = String.fromCharCode(keycode)
		if inv_key in @popup.inventory.getKeys()
			item = @popup.inventory.getItem(inv_key)
			if @popup.context == "drop"
				@game.doPlayerDrop(item)
			else if @popup.context == "equip"
				@game.doPlayerEquip(item)
			else if @popup.context == "remove"
				@game.doPlayerRemove(item)
			else if @popup.context == "give"
				@game.doPlayerGive(item)
			else if @popup.context == "apply"
				@game.doPlayerApply(item, inv_key)
				# if item.group == Brew.groups.TIMEORB
				# 	@popup = {}
				# 	@showTimeOrbScreen()
				# 	return
				# else
				# 	@game.doPlayerApply(item, inv_key)

			else if @popup.context == "throw"
				@promptThrow(item, inv_key)
			else
				@showItemMenu(item)
				return true
		
		# if we had a context, go back to the game
		$("#id_div_popup").hide()
		@drawDisplayAll()
		@popup = {}
		@input_handler = null
		
	inputItemMenu: (keycode) ->
		# apply
		#if keycode == 65
		if keycode == 85 # Use
			if @popup.actions.apply
				@game.doPlayerApply(@popup.item, keycode)
				# if @popup.item.group == Brew.groups.TIMEORB
				# 	@popup = {}
				# 	@showTimeOrbScreen()
				# 	return

				# else
				# 	@game.doPlayerApply(@popup.item, keycode)
			else
				console.log("You can't apply that")
			
		# drop
		else if keycode == 68
			if @popup.actions.drop
				@game.doPlayerDrop(@popup.item)
			else
				console.log("you cant drop that")
			
		# give
		else if keycode == 71
			if @popup.actions.give
				@game.doPlayerGive(@popup.item)
			else
				console.log("you cant drop that")

		# equip 
		else if keycode == 69
			if @popup.actions.equip
				@game.doPlayerEquip(@popup.item)
			else
				console.log("you cant equip that ")
		
		# throw
		else if keycode == 84
			if @popup.actions.throw
				@promptThrow(@popup.item)
				
			else
				console.log("you cant THROW THAT")
		
		# remove
		else if keycode == 82
			if @popup.actions.remove
				@game.doPlayerRemove(@popup.item)
			else
				console.log("you cant remove that!")

		# otherwise, cancel back
		else
			@showInventory()
			return true
		
		# if we did something, go back to the game
		$("#id_div_popup").hide()
		@drawDisplayAll()
		@popup = {}
		@input_handler = null

	inputPopupToDismiss: (keycode) ->
		# space : dismiss
		if keycode in [32, 13, 27]
			# if we did something, go back to the game
			$("#id_div_popup").hide()
			@drawDisplayAll()
			@popup = {}
			@input_handler = null

	inputDied: (keycode) ->
		# enter: new game
		if keycode == 13
			$("#id_div_popup").hide()
			@drawDisplayAll()
			@popup = {}
			@input_handler = null
			window.location.replace("http://www.dungeondual.com/creategame/")

		# esc: return to menu
		else if keycode == 27
			$("#id_div_popup").hide()
			@drawDisplayAll()
			@popup = {}
			@input_handler = null
			window.location.replace("http://www.dungeondual.com/")

	inputChat: (keycode, shiftKey) ->
		# enter : send
		if keycode == 13
			# send it!
			@game.socket.sendChat(@popup.text)

			$("#id_div_popup").hide()
			@drawDisplayAll()
			@popup = {}
			@input_handler = null

		# esc: nevermind
		else if keycode == 27
			$("#id_div_popup").hide()
			@drawDisplayAll()
			@popup = {}
			@input_handler = null

		# backspace / delete
		else if keycode == 46
			if @popup.text
				@popup.text = @popup.text[0..@popup.text.length-2]
				@showChat()

		else
			letter = Brew.utils.mapKeyPressToActualCharacter(keycode, shiftKey)
			if @popup.text.length < (Brew.config.screen_tiles_width - 2)
				@popup.text += letter
			@showChat()

	inputTimeOrb: (keycode, shiftKey) ->
		if keycode in [32, 13, 27]
			# if we did something, go back to the game
			$("#id_div_popup").hide()
			@drawDisplayAll()
			@popup = {}
			@input_handler = null



	# ------------------------------------------------------------
	# MOUSE input
	# ------------------------------------------------------------

	mouseDown: (grid_obj_xy, button, shift_key) ->
		map_xy = @my_view.add(grid_obj_xy)
		player = @gamePlayer()

		# check if there is a monster we want to shoot at
		target_mob = @gameLevel().getMonsterAt(map_xy)
		target_is_player = target_mob? and Brew.utils.compareThing(target_mob, player)

		# clicked on ourselves -- do nothing?
		if target_is_player
			# @game.doPlayerAction()
			return false
		
		# clicked on a tile, execute against it ?
		else
			if shift_key
				# debug: add monster
				@game.debugClick(map_xy)
			else
				@game.doPlayerClick(map_xy)

		@game.lastKeypress = new Date()

	mouseLongClick: (grid_obj_xy, button, shift_key) ->
		map_xy = @my_view.add(grid_obj_xy)
		m = @gameLevel().getMonsterAt(map_xy)
		if m?
			@popup.monster = m
			@showMonsterInfo()

	mouseGainFocus: (grid_obj_xy) ->
		grid_manager.drawBorderAt(grid_obj_xy, 'white')
		grid_xy = new Coordinate(grid_obj_xy.x, grid_obj_xy.y)
		map_xy = @my_view.add(grid_xy)
		@drawFooter(map_xy)

		if @game.my_player.active_ability?
			if @game.abil.checkUseAt(@game.my_player.active_ability, map_xy)
				# draw[2] = ROT.Color.add(draw[2], [0, 50, 0])
				# grid_manager.drawBorderAt(grid_obj_xy, 'green')
				@highlights[map_xy.toKey()] = Brew.colors.green
				@drawMapAt(map_xy)
		
	mouseLeaveFocus: (grid_obj_xy) ->
		grid_xy = new Coordinate(grid_obj_xy.x, grid_obj_xy.y)
		map_xy = @my_view.add(grid_xy)
		delete @highlights[grid_xy.toKey()]
		@drawDisplayAt(grid_xy)

	# ------------------------------------------------------------
	# PAIR MOUSE input
	# ------------------------------------------------------------

	mouseDownPair: (grid_obj_xy, button, shift_key) ->
		if not @game.is_paired
			return false

		pair_map_xy = @game.pair.view.xy.add(grid_obj_xy)
		@game.doPlayerPairClick(pair_map_xy)
		return true

	mouseGainFocusPair: (grid_obj_xy) ->
		if not @game.is_paired
			return false

		pair_grid_manager.drawBorderAt(grid_obj_xy, 'white')
		pair_map_xy = @game.pair.view.xy.add(grid_obj_xy)

		if @game.my_player.active_ability?
			if @game.abil.checkPairUseAt(@game.my_player.active_ability, pair_map_xy)
				# pair_grid_manager.drawBorderAt(grid_obj_xy, 'green')
				drawing = @displayat[pair_map_xy.toKey()]
				@my_pair_display.draw(grid_obj_xy.x, grid_obj_xy.y, drawing[0], drawing[1], "green")
		
	mouseLeaveFocusPair: (grid_obj_xy) ->
		if not @game.is_paired
			return false

		grid_xy = new Coordinate(grid_obj_xy.x, grid_obj_xy.y)
		@updatePairDisplayAt(grid_xy)

	# ------------------------------------------------------------
	# on-screen DIALOG
	# ------------------------------------------------------------

	showDialogAbove: (loc_xy, msg, color_rgb) ->
		above_xy = if loc_xy.y == 0 then loc_xy.add(new Coordinate(0, 1)) else loc_xy.subtract(new Coordinate(0, 1))
		return @showDialog(above_xy, msg, color_rgb)
		
	showDialog: (loc_xy, msg, color_rgb) ->
		color_rgb ?= Brew.colors.white
		color_hex = ROT.Color.toHex(color_rgb)

		far_right = loc_xy.x + msg.length
		if far_right >= Brew.config.screen_tiles_width
			offset = far_right - Brew.config.screen_tiles_width
			loc_xy = loc_xy.subtract(new Coordinate(offset, 0))

		@my_dialog_display.drawText(loc_xy.x, loc_xy.y, "%c{#{color_hex}}#{msg}")
		x = loc_xy.x * @my_tile_width
		y = loc_xy.y * @my_tile_height

		setTimeout(=>
			@my_dialog_display._backend._context.clearRect(x, y, @my_tile_width * msg.length, @my_tile_height)
		2000)


	# ------------------------------------------------------------
	# DEBUG
	# ------------------------------------------------------------

	debugMonsterFov: () ->
		# cycle through monster FOV

		# here are all our monsters
		monsters = @gameLevel().getMonsters()
		fov_monster = null

		if monsters.length == 0
			console.log("No monsters on the level")

		if not @debug.fov.monster?
			# if we arent already showing one, pick the first
			@debug.fov.monster = monsters[0]

		else
			indices = (m.id for m in monsters)
			current_idx = indices.indexOf(@debug.fov.monster.id)
			new_idx = current_idx + 1
			if new_idx > monsters.length
				# all done cycling
				@debug.fov = {}

			else
				@debug.fov.monster = monsters[new_idx]

		@drawDisplayAll()

	debugPathMaps: () ->
		# cycle through monster pathmaps
		# press q first time = initialize list, index pointer
		# press q next time = cycle through list
		# get to start of list again = quit

		if not @debug.pathmaps.list?
			# create a list of all pathmaps
			@debug.pathmaps.list = []
			@debug.pathmaps.index = -1

			# here are all our monsters
			for monster in @gameLevel().getMonsters()
				for own key, pathmap of monster.pathmaps
					title = "#{ monster.name } #{ monster.id } #{ key }"
					@debug.pathmaps.list.push([title, pathmap])

			# generic game pathmaps
			for own key, pathmap of @game.pathmaps
				title = "game #{ key }"
				@debug.pathmaps.list.push([title, pathmap])

		# clear the screen first i guess
		arg = @debug.pathmaps.index
		delete @debug.pathmaps["index"]
		@drawDisplayAll()

		@debug.pathmaps.index = arg

		# we have a list, increment and display it
		@debug.pathmaps.index += 1
		if @debug.pathmaps.index == @debug.pathmaps.list.length
			# turn it off
			@debug.pathmaps = {}
		else
			console.log("showing pathmap: " + @debug.pathmaps.list[@debug.pathmaps.index][0])

		@drawDisplayAll()

	# debugUpdatePairDisplay: () ->
	# 	@game.socket.requestDisplayUpdate()

	debugAtCoords: () ->
		grid_obj_xy = grid_manager.getLastVisitGrid()
		map_xy = coordFromObject(grid_obj_xy)
		console.log("grid xy", grid_obj_xy)
		console.log("map xy", map_xy)
		key = map_xy.toKey()
		console.log("key", key)
		
		console.log("terrain", @gameLevel().getTerrainAt(map_xy))
		
		f = @gameLevel().getFeatureAt(map_xy)
		console.log("feature", if f? then f else "none")

		i = @gameLevel().getItemAt(map_xy)
		console.log("item", if i? then i else "none")

		m = @gameLevel().getMonsterAt(map_xy)
		console.log("monster", if m? then m else "none")

		o = @gameLevel().getOverheadAt(map_xy)
		console.log("overhead", if o? then o else "none")

		console.log("can_view", @gamePlayer().canView(map_xy))
		console.log("light", @gameLevel().getLightAt(map_xy))
		console.log("light (NoA)", @gameLevel().getLightAt_NoAmbient(map_xy))
		true
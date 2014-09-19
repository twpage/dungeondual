class Brew.UserInterface
	constructor: (@game, display_info) ->
		# save displays object refs 
		@my_display = display_info["game"]
		@my_layer_display = display_info["layer"]
		@my_dialog_display = display_info["dialog"]

		@my_tile_width = @my_display.getContainer().width / Brew.panels.full.width
		@my_tile_height = @my_display.getContainer().height / Brew.panels.full.height

		@my_view = new Coordinate(0, 0)
		@input_handler = null
		@popup = {}
		@displayat = {}
		@highlights = {}
		@messagelog = []

		@panel_offsets = 
			"game": new Coordinate(Brew.panels.game.x, Brew.panels.game.y)
			"messages": new Coordinate(Brew.panels.messages.x, Brew.panels.messages.y)
			"footer": new Coordinate(Brew.panels.footer.x, Brew.panels.footer.y)
			"playerinfo": new Coordinate(Brew.panels.playerinfo.x, Brew.panels.playerinfo.y)
			"viewinfo": new Coordinate(Brew.panels.viewinfo.x, Brew.panels.viewinfo.y)

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
				# todo: consolidate all one-key screens, died, victory, etc
			else if @input_handler == "targeting"
				@inputTargeting(ui_keycode, shift_key)

	# ------------------------------------------------------------
	# Utils stuff
	# ------------------------------------------------------------

	screenToMap: (screen_xy) ->
		# take a screen coord from the full canvas and convert it to a map coord
		if @getPanelAt(screen_xy) != "game"
			return null
		else
			map_xy = screen_xy.subtract(@panel_offsets["game"]).add(@my_view)
			return map_xy

	mapToScreen: (map_xy) ->
		# take a map coordinate and transfer it to a full grid xy
		screen_xy = map_xy.subtract(@my_view).add(@panel_offsets["game"])
		if @getPanelAt(screen_xy) != "game"
			return null
		else
			return screen_xy

	appendBlanksToString: (text, max_length) ->
		black_hex = ROT.Color.toHex(Brew.colors.black)

		num_spaces = max_length - text.length
		spaces = ("_" for i in [0..num_spaces]).join("")
		
		return text+"%c{#{black_hex}}#{spaces}"


	setDialogDisplayTransparency: (alpha) ->
		@my_dialog_display._context.globalAlpha = alpha
	
	resetDialogDisplayTransparency: () ->
		@my_dialog_display._context.globalAlpha = 1

	# ------------------------------------------------------------
	# Drawing 
	# ------------------------------------------------------------

	drawDisplayAll: (options) ->
		@clearLayerDisplay()

		@drawGamePanel(options)
		@drawPlayerInfoPanel()
		@drawMessagesPanel()
		# @drawFooterPanel()
		
		# @drawViewInfoPanel()

	drawOnPanel: (panel_name, x, y, code, forecolor, bgcolor) ->
		panel_x = @panel_offsets[panel_name].x + x
		panel_y = @panel_offsets[panel_name].y + y
		@my_display.draw(panel_x, panel_y, code, forecolor, bgcolor)
		true

	drawTextOnPanel: (panel_name, x, y, text, max_width) ->
		panel_x = @panel_offsets[panel_name].x + x
		panel_y = @panel_offsets[panel_name].y + y
		@my_display.drawText(panel_x, panel_y, text, max_width)
		true

	drawBarOnPanel: (panel_name, start_x, start_y, max_tiles, current_amount, max_amount, full_color) ->
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

				@drawOnPanel(panel_name, start_x + i, start_y, " ", "white", ROT.Color.toHex(full_color))

			else if i < num_bars
				@drawOnPanel(panel_name, start_x + i, start_y, " ", "white", ROT.Color.toHex(full_color))

			else
				@drawOnPanel(panel_name, start_x + i, start_y, " ", "white", ROT.Color.toHex(Brew.colors.normal))

		violet_rgb = ROT.Color.toHex(full_color)
		@drawTextOnPanel(panel_name, start_x + max_tiles + 1, start_y, "%c{#{violet_rgb}}#{current_amount}%c{#{black_hex}}_")

	drawTextBarOnPanel: (panel_name, start_x, start_y, max_tiles, current_amount, max_amount, full_color, text) ->
		black_hex = ROT.Color.toHex(Brew.colors.black)

		raw_num_bars = Math.min(1.0, current_amount / max_amount) * max_tiles
		num_bars = Math.ceil(raw_num_bars)
		remainder = num_bars - raw_num_bars
		tile = null

		for i in [0..max_tiles-1]
			if i < text.length
				text_char = text[i]
			else
				text_char = " "

			if i < num_bars
				@drawOnPanel(panel_name, start_x + i, start_y, text_char, "white", ROT.Color.toHex(full_color))

			else
				@drawOnPanel(panel_name, start_x + i, start_y, text_char, "white", ROT.Color.toHex(Brew.colors.normal))

		full_rgb = ROT.Color.toHex(full_color)
		@drawTextOnPanel(panel_name, start_x + max_tiles + 1, start_y, "%c{#{full_rgb}}#{current_amount}%c{#{black_hex}}_")

	# ------------------------------------------------------------
	# figure out which panel we're in
	# ------------------------------------------------------------
	getPanelAt: (xy) ->
		# given a SCREEN XY (full screen), determine which panel we're clicking on
		panel_name = "dunno"

		if xy.x < Brew.panels.playerinfo.x
			# to the left of the info panels
			if xy.y < Brew.panels.game.y
				panel_name = "messages"
			else if xy.y < Brew.panels.footer.y
				panel_name = "game"
			else
				panel_name = "footer"
		else
			# to the right of the game panel
			if xy.x < Brew.panels.playerinfo.x
				panel_name = "playerinfo"
			else
				panel_name = "viewinfo"

		return panel_name

	# ------------------------------------------------------------
	# draw game
	# ------------------------------------------------------------

	centerViewOnPlayer: () ->
		if @gameLevel().width <= Brew.panels.game.width and @gameLevel().height <= Brew.panels.game.height
			return
			
		half_x = (@my_display.getOptions().width / 2)
		half_y = (@my_display.getOptions().height / 2)
		
		view_x = Math.min(Math.max(0, @gamePlayer().coordinates.x - half_x), @gameLevel().width - Brew.panels.game.width)
		view_y = Math.min(Math.max(0, @gamePlayer().coordinates.y - half_y), @gameLevel().height - Brew.panels.game.height)
		
		@my_view = new Coordinate(view_x, view_y)
		
	drawGamePanel: (options) ->
		for row_y in [Brew.panels.game.y..Brew.panels.game.y+Brew.panels.game.height-1]
			for col_x in [Brew.panels.game.x..Brew.panels.game.x+Brew.panels.game.width-1]
				screen_xy = new Coordinate(col_x, row_y)
				@drawGamePanelAt(screen_xy, null, options)

	drawMapAt: (map_xy, options) ->
		screen_xy = @mapToScreen(map_xy)
		if screen_xy?
			@drawGamePanelAt(screen_xy, null, options)
		
	drawGamePanelAt: (xy, map_xy, options) ->
		options ?= {}
		color_mod = options?.color_mod ? [0, 0, 0]
		# over_saturate = options?.over_saturate ? false
		over_saturate = true

		map_xy = @screenToMap(xy)
		if not map_xy?
			console.log(xy)
			return

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
		@clearDisplayAt(@my_dialog_display, xy)

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

				# features should modify fore or back color but not both
				if feature? and feature.color?
					draw[1] = ROT.Color.interpolate(terrain.color, feature.color, feature.intensity)

				else if feature? and feature.bgcolor?
					draw[2] = ROT.Color.interpolate(terrain.bgcolor, feature.bgcolor, feature.intensity)

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

		@my_display.draw(xy.x, xy.y, draw[0], ROT.Color.toHex(draw[1]), ROT.Color.toHex(draw[2]))

		if not options?.color_override?
			@displayat[map_xy.toKey()] = draw

	# ------------------------------------------------------------
	# draw HUD / playerinfo
	# ------------------------------------------------------------
	
	drawHudAll: () ->
		@drawPlayerInfoPanel()
		# @drawViewInfoPanel()

	drawPlayerInfoPanel: () ->
		# redraw the HUD
		black_hex = ROT.Color.toHex(Brew.colors.black)
		player = @gamePlayer()
		@drawTextOnPanel("playerinfo", 0, 0, "#{player.name}", Brew.panels.playerinfo.width)
		@drawTextOnPanel("playerinfo", 0, 1, "#{Brew.hero_type[player.hero_type].name}", Brew.panels.playerinfo.width)
		
		# health
		row = 2
		maxhp = player.getStat(Brew.stat.health).getMax()
		hp = player.getStat(Brew.stat.health).getCurrent()
		for i in [1..maxhp]
			color = if (i <= hp) then Brew.colors.red else Brew.colors.normal
			@drawOnPanel("playerinfo", i-1, row, Brew.unicode.heart, ROT.Color.toHex(color))

		# stamina
		row += 1
		@drawTextBarOnPanel("playerinfo", 0, row, Brew.panels.playerinfo.width - 3, 
			player.getStat(Brew.stat.stamina).getCurrent(), 
			player.getStat(Brew.stat.stamina).getMax(),
			Brew.colors.violet,
			"Stamina"
		)

		# abilities
		row += 1
		for i in [0..player.abilities.length-1]
			abil_name = "(#{i+1}) " + Brew.ability[player.abilities[i]].name
			@drawTextOnPanel("playerinfo", 0, row, abil_name, Brew.panels.playerinfo.width)
			row += 1

		# flags
		row += 1
		flag_list = player.getFlags()
		for i in [0..6]
			if i < flag_list.length
				flag = flag_list[i]
				turn_expires = player.getFlagCount(flag)
				duration = player.getFlagCountDuration(flag)
				turns_remaining = turn_expires - @game.turn

				@drawTextBarOnPanel("playerinfo", 0, row, Brew.panels.playerinfo.width - 3, 
					turns_remaining, 
					duration,
					Brew.colors.red,
					Brew.flagDesc[flag][1]
				)

				# @drawTextOnPanel("playerinfo", 0, row, flag, Brew.panels.playerinfo.width)
			else
				spaces = ("_" for j in [0..Brew.panels.playerinfo.width-1]).join("")
				@drawTextOnPanel("playerinfo", 0, row, "%c{#{black_hex}}#{spaces}")
			row += 1

		# @drawHudSync()
		# @drawHudAbility()

	# drawHudAbility: () ->
	# 	black_hex = ROT.Color.toHex(Brew.colors.black)
	# 	player = @gamePlayer()
	# 	if player.active_ability?
	# 		abil_hotkey = player.abilities.indexOf(player.active_ability) + 1
	# 		abil_desc = "Using #{Brew.ability[player.active_ability].name.toUpperCase()} (#{abil_hotkey})"
	# 	else
	# 		abil_desc = "No ability selected"
		
	# 	start_x = Math.floor(Brew.config.screen_tiles_width / 2)
	# 	max_width = Math.floor(Brew.config.screen_tiles_width / 2)

	# 	num_spaces = max_width - abil_desc.length
	# 	spaces = ("_" for i in [0..num_spaces-1]).join("")
	# 	@my_hud_display.drawText(start_x, 0, "%c{#{black_hex}}#{spaces}%c{white}#{abil_desc}")


	# drawHudSync: () ->
	# 	# draw the sync status

	# 	black_hex = ROT.Color.toHex(Brew.colors.black)

	# 	if not @game.is_paired
	# 		status_msg = "Not Connected"
	# 		message = "No Data"
	# 	else if @game.is_paired and not @game.pair.sync
	# 		status_msg = "Connected"
	# 		message = "Awaiting Sync"
	# 	else
	# 		status_msg = if @game.pair.sync.status then "In Sync" else "Out of Sync"
	# 		message = @game.pair.sync.message

	# 	start_x = Math.floor(Brew.config.screen_tiles_width / 2)
	# 	max_width = Math.floor(Brew.config.screen_tiles_width / 2)

	# 	num_spaces = max_width - status_msg.length
	# 	spaces = ("_" for i in [0..num_spaces-1]).join("")
	# 	@my_hud_display.drawText(start_x, 1, "%c{#{black_hex}}#{spaces}%c{white}#{status_msg}")

	# 	num_spaces = max_width - message.length
	# 	spaces = ("_" for i in [0..num_spaces-1]).join("")
	# 	@my_hud_display.drawText(start_x, 2, "%c{#{black_hex}}#{spaces}%c{white}#{message}")


	# ------------------------------------------------------------
	# Message Log
	# ------------------------------------------------------------
	addMessage: (text, turncount) ->
		@messagelog.push([text, turncount])
		true

	drawMessagesPanel: () ->
		for i in [0..2]
			message = @messagelog[@messagelog.length-3+i]
			if message?
				@drawTextOnPanel("messages", 0, i, @appendBlanksToString(message[0], Brew.panels.messages.width - 1))

	# ------------------------------------------------------------
	# Footer
	# ------------------------------------------------------------
	updateTerrainFooter: (old_xy, new_xy) ->
		# called whenever the player moves to a new tile

		message = ""

		i = @gameLevel().getItemAt(new_xy)
		# f = @gameLevel().getFeatureAt(new_xy)
		old_t = @gameLevel().getTerrainAt(old_xy)
		new_t = @gameLevel().getTerrainAt(new_xy)

		if i?
			article = @getArticleForItem(i)
			message = "There is #{article}#{@game.getItemNameFromCatalog(i)} here. (SPACE to pick up)"

		else if (not Brew.utils.sameDef(old_t, new_t)) and new_t.walkover?
			message = new_t.walkover

		if message != ""
			@drawFooterPanel(message)

	drawFooterPanel: (message) ->
		@drawTextOnPanel("footer", 0, 0, @appendBlanksToString(message, Brew.panels.footer.width - 1))

	getArticleForItem: (item) ->
		article = null
		item_name = @game.getItemNameFromCatalog(item)

		if item.group == Brew.groups.ARMOR
			article = ""
		else if item_name[0].toLowerCase() in ['a', 'e', 'i', 'o', 'u']
			article = "an "
		else
			article = "a "

		return article

	getMouseoverDescriptionForFooter: (look_xy) ->
		
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
				tap = null
				if memory.objtype == "item"
					tap = "#{@getArticleForItem(memory)}#{memory.name}"
				else
					tap = if memory.description? then memory.description else memory.name.toLowerCase()
				message = "You remember seeing #{tap} there"
			else
				message = "You don't see anything"
		else
			t_desc = if t.description? then t.description else t.name.toLowerCase()
			if m? and Brew.utils.compareThing(m, @gamePlayer())
				message = "You are standing on #{t_desc}"
			else if m?
				message = "#{m.name}"

			else if i?
				message = "You see #{@getArticleForItem(i)}#{@game.getItemNameFromCatalog(i)}"

			else
				message = "You see #{t_desc}"

		return message

	# ------------------------------------------------------------
	# handle on-screen targeting
	# ------------------------------------------------------------

	updateAndDrawTargeting: (target_xy) ->
		# clear old line if any
		old_line = @popup.line ? []

		for xy in old_line
			delete @highlights[xy.toKey()]
			@drawMapAt(xy)

		# get the new line
		if @gamePlayer().coordinates.compare(target_xy)
			line = [@gamePlayer().coordinates]
		else
			line = Brew.utils.getLineBetweenPoints(@gamePlayer().coordinates, target_xy)

		for xy in line
			@highlights[xy.toKey()] = Brew.colors.yellow
			@drawMapAt(xy)

		@popup.line = line
		@popup.xy = target_xy

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

	activateDialogScreen: (title, instruct_text, highlight_color) ->
		if instruct_text == ""
			instruct_text = "Press any key to dismiss"

		highlight_color ?= Brew.colors.white

		# dim the screen background
		@drawDisplayAll({ color_override: Brew.colors.dim_screen})

		@resetDialogDisplayTransparency()
		@clearDialogDisplay()

		@drawBorders(@my_dialog_display, highlight_color, 
		{
			x: Brew.panels.game.x
			y: Brew.panels.game.y
			width: Brew.panels.game.width - 1
			height: Brew.panels.game.height - 1
		})
		
		color_hex = ROT.Color.toHex(highlight_color)
		@my_dialog_display.drawText(
			Brew.panels.game.x + 1, 
			Brew.panels.game.y + 0, 
			"%c{#{color_hex}}[ #{title} ]"
			)

		@my_dialog_display.drawText(
			Brew.panels.game.x + 1, 
			Brew.panels.game.y + Brew.panels.game.height - 1, 
			"%c{#{color_hex}}[ #{instruct_text} ]"
			)

		@input_handler = "popup_to_dismiss"

	showInfoScreen: () ->
		title = @game.getItemNameFromCatalog(@popup.item)
		instructions = "Press any key to dismiss"
		@activateDialogScreen(title, instructions, Brew.colors.pink)

		# draw description
		@my_dialog_display.drawText(
			Brew.panels.game.x + 1, 
			Brew.panels.game.y + 3, 
			@popup.item.description, 
			Brew.panels.game.width - 1
			)

	showInventory: ->
		# draw inventory on dialog screen 

		color_title_hex = ROT.Color.toHex(Brew.colors.inventorymenu.title)
		color_text_hex = ROT.Color.toHex(Brew.colors.inventorymenu.text)
		color_hotkey_hex = ROT.Color.toHex(Brew.colors.inventorymenu.hotkey)

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

		@activateDialogScreen(inventory_title, "Select Item, or any other key to dismiss", Brew.colors.inventorymenu.border)

		y = Brew.panels.game.y + 2
		for own key, item of @gamePlayer().inventory.items
			if not filter_fn(item) then continue
			
			# lower_key = String.fromCharCode(key.charCodeAt(0)+32) # i think lowercase loosk better
			@my_dialog_display.draw(Brew.panels.game.x + 1, y, item.inv_key_lower, color_hotkey_hex)
			@my_dialog_display.draw(Brew.panels.game.x + 3, y, item.code, ROT.Color.toHex(item.color))
			
			text = "%c{#{color_text_hex}}" + @game.getItemNameFromCatalog(item)
			if item.equip
				text += " (Equipped)"
			@my_dialog_display.drawText(Brew.panels.game.x + 5, y, text)
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
				@popup.terrain[offset_info.numpad_keycode] = terrain
				# @popup.terrain[offset_info.wasd_keycode] = terrain
				
				## draw the terrain
				@my_dialog_display.draw(Brew.panels.game.x + 1, y, offset_info.unicode, ROT.Color.toHex(Brew.colors.white))
				@my_dialog_display.draw(Brew.panels.game.x + 3, y, terrain.code, ROT.Color.toHex(terrain.color))
				text = "%c{#{color_text_hex}}" + terrain.name
				@my_dialog_display.drawText(Brew.panels.game.x + 5, y, text)
				y += 1
			
		@popup.inventory = @gamePlayer().inventory
		@input_handler = "inventory"

	showItemMenu: (item) ->
		# travel from inventory menu to item menu

		@clearDialogDisplay()
		
		color_title_hex = ROT.Color.toHex(Brew.colors.itemmenu.title)
		color_text_hex = ROT.Color.toHex(Brew.colors.itemmenu.text)
		color_hotkey_hex = ROT.Color.toHex(Brew.colors.itemmenu.hotkey)

		item_title = @game.getItemNameFromCatalog(item)
		@activateDialogScreen(item_title, "", Brew.colors.itemmenu.border)

		# draw the description
		@my_dialog_display.drawText(
			Brew.panels.game.x + 1, 
			Brew.panels.game.y + 3,
			@game.getItemDescription(item), 
			Brew.panels.game.width - 2
			)

		# work-around to add some extra text to item descriptions
		extra_desc = ""
		if item.group == Brew.groups.WEAPON
			extra_desc = "Damage: #{item.damage}"
		else if item.group == Brew.groups.ARMOR
			extra_desc = "Block: #{item.block}"
		else if item.group == Brew.groups.HAT
			extra_desc = "Hats are just decorative for now"

		# draw the 'extra' description
		@my_dialog_display.drawText(
			Brew.panels.game.x + 1, 
			Brew.panels.game.y + 8,
			extra_desc, 
			Brew.panels.game.width - 2
			)

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
				@my_dialog_display.drawText(
					Brew.panels.game.x + 2, 
					Brew.panels.game.y + 10 + i, 
					"%c{#{color_hotkey_hex}}" + action_name[0].toUpperCase() + "%c{#{color_text_hex}}" + action_name[1..]
					)
				i += 1
		
		@popup.item = item
		@popup.actions = actions
		@input_handler = "item_menu"

	showChat: () ->
		@activateDialogScreen("Chat", "ENTER sends - press ESCAPE to cancel", Brew.colors.cyan)
		@my_dialog_display.drawText(Brew.panels.game.x + 1, Brew.panels.game.y + 1, "Say what? <use delete to erase>")
		@my_dialog_display.drawText(Brew.panels.game.x + 1, Brew.panels.game.y + 2, "%c{cyan}#{@popup.text}", Brew.panels.game.width - 2)

		@input_handler = "chat"

	showDied: () ->
		@activateDialogScreen("Died", "Press ENTER to restart, or ESC for the menu")

		@my_dialog_display.drawText(Brew.panels.game.x + 1, Brew.panels.game.y + 1, "Congratulations, you have died!")

		@input_handler = "died"

	showVictory: () ->
		@activateDialogScreen("Victory", "Press ENTER to restart, or ESC for the menu")

		@my_dialog_display.drawText(Brew.panels.game.x + 1, Brew.panels.game.y + 1, "Congratulations, you defeated the Time Master")
		@my_dialog_display.drawText(Brew.panels.game.x + 1, Brew.panels.game.y + 2, "and saved the realm.")
		@my_dialog_display.drawText(Brew.panels.game.x + 1, Brew.panels.game.y + 4, 
			"I really wish I had a better victory screen for you, but it is day 7 and 4 hours to go so this is all you get! Oh, and a database entry! Thanks for playing!", 
			Brew.panels.game.width - 2
			)

		@input_handler = "died"

	showHelp: () ->
		@activateDialogScreen("Help")

		@my_dialog_display.drawText(Brew.panels.game.x + 1, Brew.panels.game.y + 1, Brew.helptext, Brew.panels.game.width - 2)
		@input_handler = "popup_to_dismiss"

	showMonsterInfo: () ->
		@activateDialogScreen(@popup.monster.name)

		desc = if @popup.monster.description? then @popup.monster.description else "No description"
		@my_dialog_display.drawText(Brew.panels.game.x + 1, Brew.panels.game.y + 3, desc, Brew.panels.game.width - 2)

		i = 0
		for flag in @popup.monster.getFlags()
			desc = Brew.flagDesc[flag][0]
			@my_dialog_display.drawText(Brew.panels.game.x + 1, Brew.panels.game.y + 8 + i, desc, Brew.panels.game.width - 2)
			i += 1

		@input_handler = "popup_to_dismiss"

	showAbilities: () ->
		## todo: new menu color for abilities
		color_title_hex = ROT.Color.toHex(Brew.colors.itemmenu.title)
		color_text_hex = ROT.Color.toHex(Brew.colors.itemmenu.text)
		color_hotkey_hex = ROT.Color.toHex(Brew.colors.itemmenu.hotkey)
		
		@activateDialogScreen("Abilities and Spells", "", Brew.colors.itemmenu.border)
		
		row_start = 3

		for abil, idx in @gamePlayer().getAbilities()
			@my_dialog_display.drawText(Brew.panels.game.x + 2, Brew.panels.game.y + row_start+idx, "(#{idx+1}) #{Brew.ability[abil].name}")
			@my_dialog_display.drawText(Brew.panels.game.x + 2, Brew.panels.game.y + row_start+idx+1, "#{Brew.ability[abil].description}")
			@my_dialog_display.drawText(Brew.panels.game.x + 2, Brew.panels.game.y + row_start+idx+2, if Brew.ability[abil].pair then "Can be used to help allies" else "")

			row_start += 3

		@input_handler = "abilities"

	showTargeting: (ability, keycode) ->
		@popup.context = "target"
		@popup.ability = ability
		@popup.keycode = keycode
		
		range = if @popup.ability? then Brew.ability[@popup.ability].range else @gamePlayer.getAttackRange()

		@popup.targets = @game.getPotentialTargets(@gamePlayer(), {
			range: range,
			blocksblockedByOtherTargets: if @popup.ability? then Brew.ability[@popup.ability].pathing else true,
			blockedByTerrain: true
			})

		if @popup.targets.length == 0
			@drawTextOnPanel("footer", 0, 0, @appendBlanksToString("No targets in range", Brew.panels.footer.width))
			@drawRangeOverlay(@gamePlayer().coordinates, range, Brew.colors.yellow)
			@input_handler = "popup_to_dismiss"

		else
			@popup.target_index = 0
			first_target = @popup.targets[0]

			@updateAndDrawTargeting(first_target.coordinates)

			@drawTextOnPanel("footer", 0, 0, @appendBlanksToString("Targeting #{ability}", Brew.panels.footer.width))
		
			@input_handler = "targeting"

		return true

	drawRangeOverlay: (center_xy, range, color) ->
		# draw a circle on the dialog display

		start_x = center_xy.x - range
		start_y = center_xy.y - range
		
		@setDialogDisplayTransparency(0.5)

		for x in [start_x..start_x+range*2]
			for y in [start_y..start_y+range*2]
				
				dist = Brew.utils.dist2d_xy(center_xy.x, center_xy.y, x, y)
				
				if dist <= range
					xy = new Coordinate(x, y)
					t = @gameLevel().getTerrainAt(xy)
					if t? and @gamePlayer().canView(xy)
						@my_dialog_display.draw(Brew.panels.game.x + x, Brew.panels.game.y + y, " ", null, ROT.Color.toHex(color))

	drawHighlightStairs: (stairs_type) ->
		# draw a highlight over the stairs if they've been found

		@resetDialogDisplayTransparency()

		exit_xy = @gameLevel().exit_xy
		entrance_xy = @gameLevel().start_xy
		if exit_xy? and stairs_type == "exit"
			stairs_xy = exit_xy
		else if entrance_xy and stairs_type == "entrance"
			stairs_xy = entrance_xy
		else
			@game.msg("You haven't found those stairs yet.")
			return false

		can_view = @gamePlayer().canView(stairs_xy)
		memory = @gamePlayer().getMemoryAt(@gameLevel().id, stairs_xy)
		if can_view or (memory?)
			@drawRangeOverlay(exit_xy, 2, Brew.colors.yellow)
			@input_handler = "popup_to_dismiss"
			return true

		else
			@game.msg("You haven't found the stairs yet.")
			return false

	# ------------------------------------------------------------
	# keyboard input
	# ------------------------------------------------------------

	inputGameplay: (keycode, shift_key) ->

		# movement keys
		if keycode in Brew.keymap.MOVEKEYS
			offset_xy = Brew.utils.getOffsetFromKey(keycode)
			@game.movePlayer(offset_xy)			

		# DO ACTION: space, NUMPAD 0
		else if keycode in Brew.keymap.GENERIC_ACTION
			@game.doPlayerAction()
			
		# d : drop
		else if keycode in Brew.keymap.DROP
			@popup.context = "drop"
			@showInventory()
		
		# e : equip
		else if keycode in Brew.keymap.EQUIP
			@popup.context = "equip"
			@showInventory()

		# r : remove
		else if keycode in Brew.keymap.REMOVE
			@popup.context = "remove"
			@showInventory()
			
		# a : apply / arm / activate / use
		else if keycode in Brew.keymap.APPLY
			@popup.context = "apply"
			@showInventory()
			
		# # t : throw
		# else if keycode == 84
		# 	@popup.context = "throw"
		# 	@showInventory()
			
		# t : talk
		else if keycode in Brew.keymap.TALK
			@popup.context = "chat"
			@popup.text = ""
			@showChat()

		# # u : use
		# else if keycode in Brew.keymap.USE
		# 	@popup.context = "apply"
		# 	@showInventory()

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

		else if keycode in Brew.keymap.STAIRS_DOWN
			@drawHighlightStairs("exit")

		else if keycode in Brew.keymap.STAIRS_UP
			@drawHighlightStairs("entrance")

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

			else if @popup.context == "throw"
				@promptThrow(item, inv_key)
			else
				@showItemMenu(item)
				return true
		
		# if we had a context, go back to the game
		@clearDialogDisplay()
		@drawDisplayAll()
		@popup = {}
		@input_handler = null
		
	inputItemMenu: (keycode) ->
		# apply
		#if keycode == 65
		if keycode == 85 # Use
			if @popup.actions.apply
				@game.doPlayerApply(@popup.item, keycode)
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
				console.log("you cant T-HROW that")
		
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
		@clearDialogDisplay()
		@drawDisplayAll()
		@popup = {}
		@input_handler = null

	inputSpaceToDismiss: (keycode) ->
		# space : dismiss
		if keycode in [32, 13, 27]
			# go back to the game
			@clearDialogDisplay()
			@drawDisplayAll()
			@popup = {}
			@input_handler = null

	inputPopupToDismiss: (keycode) ->
		# any key to dismiss
		@clearDialogDisplay()
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
			if @popup.text.length < (Brew.panels.game.width - 2)
				@popup.text += letter
			@showChat()

	inputTargeting: (keycode, shift_key) ->
		popup_xy = clone(@popup.xy)

		# movement keys
		if keycode in Brew.keymap.MOVEKEYS
			offset_xy = Brew.utils.getOffsetFromKey(keycode)
			target_xy = popup_xy.add(offset_xy)
			@popup.target_index = -1 # break current target index ordering
			@updateAndDrawTargeting(target_xy)

		# DO ACTION: space, NUMPAD 0
		else if keycode in Brew.keymap.GENERIC_ACTION or (@popup.ability? and keycode == @popup.keycode)
			@input_handler = null
			@highlights = {}
			@drawDisplayAll()
			@game.doTargetingAt(@popup.ability, @popup.xy)
			@popup = {}

		# cancel
		else if keycode in Brew.keymap.EXIT_OR_CANCEL
			@input_handler = null
			@highlights = {}
			@clearDialogDisplay()
			@drawDisplayAll()
			@popup = {}

		else if keycode in Brew.keymap.CYCLE_TARGET
			if @popup.target_index == -1
				@popup.target_index = 0
			else
				@popup.target_index = (@popup.target_index + 1).mod(@popup.targets.length)

			@updateAndDrawTargeting(@popup.targets[@popup.target_index].coordinates)

	# ------------------------------------------------------------
	# MOUSE input
	# ------------------------------------------------------------

	mouseDown: (grid_obj_xy, button, shift_key) ->
		map_xy = @my_view.add(grid_obj_xy).subtract(@panel_offsets["game"])
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
		map_xy = @my_view.add(grid_obj_xy).subtract(@panel_offsets["game"])
		m = @gameLevel().getMonsterAt(map_xy)
		if m?
			@popup.monster = m
			@showMonsterInfo()

	mouseGainFocus: (grid_obj_xy) ->
		grid_xy = new Coordinate(grid_obj_xy.x, grid_obj_xy.y)

		# ignore any mouse movement outside main game screen -- for now
		if @getPanelAt(grid_xy) != "game"
			return

		# handle special case for targetting mode
		if @popup.context == "target"
			@updateAndDrawTargeting(@screenToMap(grid_xy))

		# normal case - follow mouse around with a border
		# only update mouse-over when not in a dialog menu
		else if @input_handler == null
			grid_manager.drawBorderAt(grid_obj_xy, 'white')
			
			map_xy = @screenToMap(grid_xy)
			@drawFooterPanel(@getMouseoverDescriptionForFooter(map_xy))

			if @game.my_player.active_ability?
				if @game.abil.checkUseAt(@game.my_player.active_ability, map_xy)
					# draw[2] = ROT.Color.add(draw[2], [0, 50, 0])
					# grid_manager.drawBorderAt(grid_obj_xy, 'green')
					@highlights[map_xy.toKey()] = Brew.colors.green
					@drawMapAt(map_xy)
		
	mouseLeaveFocus: (grid_obj_xy) ->
		# only update mouse-over when not in a dialog menu
		if @input_handler == null
			grid_xy = new Coordinate(grid_obj_xy.x, grid_obj_xy.y)
			if @getPanelAt(grid_xy) != "game"
				return

			map_xy = @screenToMap(grid_xy)
			delete @highlights[map_xy.toKey()]
			@drawMapAt(map_xy)

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
		map_xy = @my_view.add(grid_obj_xy).subtract(@panel_offsets["game"])
		# map_xy = coordFromObject(grid_obj_xy)
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

		mem = @gamePlayer().getMemoryAt(@gameLevel().id, map_xy)
		console.log("memory", if mem? then mem else "none")

		console.log("can_view", @gamePlayer().canView(map_xy))
		console.log("light", @gameLevel().getLightAt(map_xy))
		console.log("light (NoA)", @gameLevel().getLightAt_NoAmbient(map_xy))
		true
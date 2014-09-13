window.Brew.keymap =
	MOVE_LEFT: [ROT.VK_LEFT, ROT.VK_NUMPAD4] #, ROT.VK_A]
	MOVE_RIGHT: [ROT.VK_RIGHT, ROT.VK_NUMPAD6] #, ROT.VK_D]
	MOVE_UP: [ROT.VK_UP, ROT.VK_NUMPAD8] #, ROT.VK_W]
	MOVE_DOWN: [ROT.VK_DOWN, ROT.VK_NUMPAD2] #, ROT.VK_S]

	# diagonals
	MOVE_DOWNLEFT: [ROT.VK_NUMPAD1]
	MOVE_DOWNRIGHT: [ROT.VK_NUMPAD3]
	MOVE_UPLEFT: [ROT.VK_NUMPAD7]
	MOVE_UPRIGHT: [ROT.VK_NUMPAD9]

	GENERIC_ACTION: [ROT.VK_SPACE, ROT.VK_NUMPAD5]
	TALK: [ROT.VK_T]
	USE: [ROT.VK_U]
	INVENTORY: [ROT.VK_I]
	SHOW_ABILITIES: [ROT.VK_Z]

# 		else if keycode == 191 # / ? help
# 			@showHelp()

	HELP: [ROT.VK_SLASH, ROT.VK_QUESTION_MARK]

# 		else if keycode == 192 ## back tick `
# 			@debugAtCoords()
	DEBUG: [ROT.VK_BACK_QUOTE]

	ABILITY_HOTKEY: [ROT.VK_1, ROT.VK_2, ROT.VK_3, ROT.VK_4, ROT.VK_5, ROT.VK_6]

# 		# # d : drop
# 		# else if keycode == 68
# 		# 	@popup.context = "drop"
# 		# 	@showInventory()
		
# 		# # e : equip
# 		# else if keycode == 69
# 		# 	@popup.context = "equip"
# 		# 	@showInventory()

# 		# # r : remove
# 		# else if keycode == 82
# 		# 	@popup.context = "remove"
# 		# 	@showInventory()
			
# 		# # a : apply / arm / activate
# 		# else if keycode == 65
# 		# 	@popup.context = "apply"
# 		# 	@showInventory()
			
# 		# # q : toggle pathmaps debug
# 		# else if keycode == 81
# 		# 	@debugPathMaps()
		
# 		# # / : toggle FOV debug
# 		# else if keycode == 191 
# 		# 	@debugMonsterFov()

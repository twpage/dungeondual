mySocket = null
MIN_UPDATE_PLAYER_MOVE = 2000

class Message
	constructor: (@game_id, @user_id, @msgType, @msgData) ->
		true

class window.Brew.Socket
	constructor: (@game) ->
		@game_id = @game.game_id
		@user_id = @game.user_id
		@last_sent = null
		@sending = false

		## initialize new socket connection
		mySocket = new window.WebSocket(
			"ws://108.59.10.243:10496/?game_id=#{@game_id}&user_id=#{@user_id}"
		)
		mySocket.onopen = () =>
			@on_open

		mySocket.onmessage = (socket_evt) =>
			data = JSON.parse(socket_evt.data)
			@on_message(data)
		
	gamePlayer: () ->
		return @game.my_player

	gameLevel: () ->
		return @game.my_level

	createMessage: (msgType, msgData) ->
		return new Message(@game_id, @user_id, msgType, msgData)

	pairUpdateClosed: (user_id) ->
		@game.is_paired = false
		@game.msg("User #{user_id} has left the dungeon")
		@game.my_level.removeOverheadAt(@game.pair.player.coordinates)
		@game.is_paired = false
		@game.pair = {}
		@game.updatePairSync()
		@game.ui.drawHudSync()

	pairUpdateOpen: (user_id) ->
		@game.is_paired = true
		@game.pair.user_id = user_id
		@game.msg("User #{user_id} has joined the dungeon")
		@sendDisplayUpdate()
		@requestDisplayUpdate()
		@game.updatePairSync()
		@game.ui.drawHudSync()

	sendChat: (text) ->
		msg = @createMessage("CHAT_GAME", 
		{
			"text": text
		})
		@sendMessage(msg)

	receiveChat: (user_id, data) ->
		text = data.text
		@game.ui.showDialogAbove(@game.pair.player.coordinates, text, Brew.colors.light_blue)
		@game.msg(text)

	sendMonster: (monster) ->
		# banish monster to the other player
		msg = @createMessage("INCOMING_MONSTER", {
			"monster": monster.toObject()
		})
		@sendMessage(msg)

	sendItem: (item) ->
		# banish monster to the other player
		msg = @createMessage("INCOMING_ITEM", {
			"item": item.toObject()
		})
		@sendMessage(msg)

	sendDisplayUpdate: () ->
		msg = @createMessage("DISPLAY_UPDATE", 
		{
			"drawgrid": @game.ui.displayat
			"player":
				"xy": @gamePlayer().coordinates.toObject()
			"view":
				"xy": @game.ui.my_view.toObject()
			# "monsters": (m.toObject() for m in @gameLevel().getMonsters() when @gamePlayer().hasKnowledgeOf(m))
			"level_depth": @gameLevel().depth
			"turn": @game.turn
			"username": @gamePlayer().name
		})
		@sendMessage(msg)

	requestDisplayUpdate: () ->
		# console.log("sending display request")
		msg = @createMessage("DISPLAY_REQUEST", {})
		@sendMessage(msg)

	receiveDisplayUpdate: (user_id, data) ->
		console.log("received display UPDATE from #{user_id}")
		@game.pair.view = 
			xy: coordFromObject(data.view.xy)
		
		@game.pair.turn = data.turn
		@game.pair.level_depth = data.level_depth
		@game.pair.username = data.username

		@game.ui.updatePairDisplay(data.drawgrid)
		@game.updatePairGhost(coordFromObject(data.player.xy))

		@game.updatePairSync()

		# monsters
		# @game.updateMonsterPairs(data.level_depth, data.monsters)

		true

	receiveDisplayRequest: (user_id, data) ->
		## process request and send it back
		# console.log("received display request from #{user_id}")
		@sendDisplayUpdate()
	
	sendAbilityClick: (player_xy, ability, target_xy) ->
		## send an ability over?????????????????????????????????????????????
		msg = @createMessage("INCOMING_ABILITY", {
			"player_xy": player_xy.toObject()
			"ability": ability
			"target_xy": target_xy.toObject()
		})
		@sendMessage(msg)

	receiveAbilityClick: (user_id, data) ->
		player_xy = coordFromObject(data.player_xy)
		ability = data.ability
		target_xy = coordFromObject(data.target_xy)
		console.log("received ability click #{ability}", player_xy, target_xy)
		@game.incoming_ability = 
			"from_xy": player_xy
			"to_xy": target_xy
			"ability": ability

	receiveItem: (user_id, data) ->
		console.log("received incoming item #{data}")
		@game.incoming_item = data.item

	receiveMonster: (user_id, data) ->
		console.log("received incoming monster #{data}")
		@game.incoming_monster = data.monster

		
	sendMessage: (msg) ->
		# mySocket.send(JSON.stringify(msg))
		true

	on_open: () ->
		# mySocket.send("Connection opened")
		true

	on_message:  (socket_msg) ->
		if not socket_msg.msgType?
			## not a valid DD socket message ???
			console.error("got a weird socket message #{socket_msg}")
			return false

		if socket_msg.msgType == "ECHO"
			console.log("ignoring echo message #{socket_msg.msgData}")

		user_id = socket_msg.user_id
		game_id = socket_msg.game_id
		data = socket_msg.msgData
		if socket_msg.msgType == "PAIR_STATUS"
			status = data.STATUS

			if status == "OPEN"
				@pairUpdateOpen(user_id)

			else if status == "CLOSED"
				@pairUpdateClosed(user_id)

			else
				console.error("Unknown PAIR_STATUS socket message")

		else if @game.is_paired

			if socket_msg.msgType == "DISPLAY_REQUEST"
				@receiveDisplayRequest(user_id, data)

			else if socket_msg.msgType == "DISPLAY_UPDATE"
				@receiveDisplayUpdate(user_id, data)

			else if socket_msg.msgType == "INCOMING_ABILITY"
				@receiveAbilityClick(user_id, data)

			else if socket_msg.msgType == "CHAT_GAME"
				@receiveChat(user_id, data)

			else if socket_msg.msgType == "INCOMING_MONSTER"
				@receiveMonster(user_id, data)

			else if socket_msg.msgType == "INCOMING_ITEM"
				@receiveItem(user_id, data)

		else
			console.error("Got pair socket message while game is unpaired " + socket_msg)

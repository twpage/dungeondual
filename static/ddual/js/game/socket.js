// Generated by CoffeeScript 1.7.1
(function() {
  var MIN_UPDATE_PLAYER_MOVE, Message, mySocket;

  mySocket = null;

  MIN_UPDATE_PLAYER_MOVE = 2000;

  Message = (function() {
    function Message(game_id, user_id, msgType, msgData) {
      this.game_id = game_id;
      this.user_id = user_id;
      this.msgType = msgType;
      this.msgData = msgData;
      true;
    }

    return Message;

  })();

  window.Brew.Socket = (function() {
    function Socket(game) {
      this.game = game;
      this.game_id = this.game.game_id;
      this.user_id = this.game.user_id;
      this.last_sent = null;
      this.sending = false;
      mySocket = new window.WebSocket("ws://108.59.10.243:10496/?game_id=" + this.game_id + "&user_id=" + this.user_id);
      mySocket.onopen = (function(_this) {
        return function() {
          return _this.on_open;
        };
      })(this);
      mySocket.onmessage = (function(_this) {
        return function(socket_evt) {
          var data;
          data = JSON.parse(socket_evt.data);
          return _this.on_message(data);
        };
      })(this);
    }

    Socket.prototype.gamePlayer = function() {
      return this.game.my_player;
    };

    Socket.prototype.gameLevel = function() {
      return this.game.my_level;
    };

    Socket.prototype.createMessage = function(msgType, msgData) {
      return new Message(this.game_id, this.user_id, msgType, msgData);
    };

    Socket.prototype.pairUpdateClosed = function(user_id) {
      this.game.is_paired = false;
      this.game.msg("User " + user_id + " has left the dungeon");
      this.game.my_level.removeOverheadAt(this.game.pair.player.coordinates);
      this.game.is_paired = false;
      this.game.pair = {};
      this.game.updatePairSync();
      return this.game.ui.drawHudSync();
    };

    Socket.prototype.pairUpdateOpen = function(user_id) {
      this.game.is_paired = true;
      this.game.pair.user_id = user_id;
      this.game.msg("User " + user_id + " has joined the dungeon");
      this.sendDisplayUpdate();
      this.requestDisplayUpdate();
      this.game.updatePairSync();
      return this.game.ui.drawHudSync();
    };

    Socket.prototype.sendChat = function(text) {
      var msg;
      msg = this.createMessage("CHAT_GAME", {
        "text": text
      });
      return this.sendMessage(msg);
    };

    Socket.prototype.receiveChat = function(user_id, data) {
      var text;
      text = data.text;
      this.game.ui.showDialogAbove(this.game.pair.player.coordinates, text, Brew.colors.light_blue);
      return this.game.msg(text);
    };

    Socket.prototype.sendMonster = function(monster) {
      var msg;
      msg = this.createMessage("INCOMING_MONSTER", {
        "monster": monster.toObject()
      });
      return this.sendMessage(msg);
    };

    Socket.prototype.sendItem = function(item) {
      var msg;
      msg = this.createMessage("INCOMING_ITEM", {
        "item": item.toObject()
      });
      return this.sendMessage(msg);
    };

    Socket.prototype.sendDisplayUpdate = function() {
      var msg;
      msg = this.createMessage("DISPLAY_UPDATE", {
        "drawgrid": this.game.ui.displayat,
        "player": {
          "xy": this.gamePlayer().coordinates.toObject()
        },
        "view": {
          "xy": this.game.ui.my_view.toObject()
        },
        "level_depth": this.gameLevel().depth,
        "turn": this.game.turn,
        "username": this.gamePlayer().name
      });
      return this.sendMessage(msg);
    };

    Socket.prototype.requestDisplayUpdate = function() {
      var msg;
      msg = this.createMessage("DISPLAY_REQUEST", {});
      return this.sendMessage(msg);
    };

    Socket.prototype.receiveDisplayUpdate = function(user_id, data) {
      console.log("received display UPDATE from " + user_id);
      this.game.pair.view = {
        xy: coordFromObject(data.view.xy)
      };
      this.game.pair.turn = data.turn;
      this.game.pair.level_depth = data.level_depth;
      this.game.pair.username = data.username;
      this.game.ui.updatePairDisplay(data.drawgrid);
      this.game.updatePairGhost(coordFromObject(data.player.xy));
      this.game.updatePairSync();
      return true;
    };

    Socket.prototype.receiveDisplayRequest = function(user_id, data) {
      return this.sendDisplayUpdate();
    };

    Socket.prototype.sendAbilityClick = function(player_xy, ability, target_xy) {
      var msg;
      msg = this.createMessage("INCOMING_ABILITY", {
        "player_xy": player_xy.toObject(),
        "ability": ability,
        "target_xy": target_xy.toObject()
      });
      return this.sendMessage(msg);
    };

    Socket.prototype.receiveAbilityClick = function(user_id, data) {
      var ability, player_xy, target_xy;
      player_xy = coordFromObject(data.player_xy);
      ability = data.ability;
      target_xy = coordFromObject(data.target_xy);
      console.log("received ability click " + ability, player_xy, target_xy);
      return this.game.incoming_ability = {
        "from_xy": player_xy,
        "to_xy": target_xy,
        "ability": ability
      };
    };

    Socket.prototype.receiveItem = function(user_id, data) {
      console.log("received incoming item " + data);
      return this.game.incoming_item = data.item;
    };

    Socket.prototype.receiveMonster = function(user_id, data) {
      console.log("received incoming monster " + data);
      return this.game.incoming_monster = data.monster;
    };

    Socket.prototype.sendMessage = function(msg) {
      return true;
    };

    Socket.prototype.on_open = function() {
      return true;
    };

    Socket.prototype.on_message = function(socket_msg) {
      var data, game_id, status, user_id;
      if (socket_msg.msgType == null) {
        console.error("got a weird socket message " + socket_msg);
        return false;
      }
      if (socket_msg.msgType === "ECHO") {
        console.log("ignoring echo message " + socket_msg.msgData);
      }
      user_id = socket_msg.user_id;
      game_id = socket_msg.game_id;
      data = socket_msg.msgData;
      if (socket_msg.msgType === "PAIR_STATUS") {
        status = data.STATUS;
        if (status === "OPEN") {
          return this.pairUpdateOpen(user_id);
        } else if (status === "CLOSED") {
          return this.pairUpdateClosed(user_id);
        } else {
          return console.error("Unknown PAIR_STATUS socket message");
        }
      } else if (this.game.is_paired) {
        if (socket_msg.msgType === "DISPLAY_REQUEST") {
          return this.receiveDisplayRequest(user_id, data);
        } else if (socket_msg.msgType === "DISPLAY_UPDATE") {
          return this.receiveDisplayUpdate(user_id, data);
        } else if (socket_msg.msgType === "INCOMING_ABILITY") {
          return this.receiveAbilityClick(user_id, data);
        } else if (socket_msg.msgType === "CHAT_GAME") {
          return this.receiveChat(user_id, data);
        } else if (socket_msg.msgType === "INCOMING_MONSTER") {
          return this.receiveMonster(user_id, data);
        } else if (socket_msg.msgType === "INCOMING_ITEM") {
          return this.receiveItem(user_id, data);
        }
      } else {
        return console.error("Got pair socket message while game is unpaired " + socket_msg);
      }
    };

    return Socket;

  })();

}).call(this);

//# sourceMappingURL=socket.map

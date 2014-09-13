// Generated by CoffeeScript 1.7.1
(function() {
  var CircleRoom, Connection, CorridorsRoom, CrossRoom, RectangleRoom, Room, buildDungeon, counter, createCrossRoom, createFloorplan, createRectangleRoom, digCorridors, dummy, getDungeonOptions, getOffsetXY, getRoomFromFloorplan, idGenerator, setupMonsters, setupPortals,
    __hasProp = {}.hasOwnProperty,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  dummy = {};

  counter = Math.floor(ROT.RNG.getUniform() * 1000000);

  idGenerator = function() {
    counter += 1;
    return counter;
  };

  window.LevelGeneratorTester = (function() {
    function LevelGeneratorTester(my_display) {
      this.my_display = my_display;
      this.levelgen = new Brew.LevelGenerator(this);
      this.my_level = null;
    }

    LevelGeneratorTester.prototype.createAndShow = function() {
      var randseed;
      randseed = (new Date()).getTime();
      this.my_level = this.levelgen.create(0, Brew.config.level_tiles_width, Brew.config.level_tiles_height, {
        ambient_light: [0, 0, 0],
        noItems: true,
        levelGen: true
      }, randseed);
      return this.showMyMap();
    };

    LevelGeneratorTester.prototype.showMyMap = function() {
      var col_x, row_y, t, xy, _i, _ref, _results;
      _results = [];
      for (row_y = _i = 0, _ref = this.my_display.getOptions().height - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; row_y = 0 <= _ref ? ++_i : --_i) {
        _results.push((function() {
          var _j, _ref1, _results1;
          _results1 = [];
          for (col_x = _j = 0, _ref1 = this.my_display.getOptions().width - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; col_x = 0 <= _ref1 ? ++_j : --_j) {
            xy = new Coordinate(col_x, row_y);
            t = this.my_level.getTerrainAt(xy);
            _results1.push(this.my_display.draw(xy.x, xy.y, t.code, ROT.Color.toHex(t.color), ROT.Color.toHex(t.bgcolor)));
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    return LevelGeneratorTester;

  })();

  window.Brew.LevelGenerator = (function() {
    function LevelGenerator(game) {
      this.game = game;
      this.id = null;
    }

    LevelGenerator.prototype.create = function(depth, width, height, levelgen_options, level_seed) {
      var connections, dungeon_options, level, rooms, success, _ref;
      ROT.RNG.setSeed(level_seed);
      dungeon_options = getDungeonOptions();
      level = new Brew.Level(depth, width, height, levelgen_options);
      _ref = buildDungeon(level, dungeon_options), success = _ref[0], rooms = _ref[1], connections = _ref[2];
      if (!success) {
        throw "Critical error while building dungeon";
      }
      this.makeExciting(level);
      level.calcTerrainNavigation();
      this.setupRoomDecoration(level, rooms);
      this.growFlora(level, level.getRandomWalkableLocation(), [], 0, 8);
      setupPortals(level);
      setupMonsters(level);
      if (!(levelgen_options != null ? levelgen_options.noItems : void 0)) {
        this.setupItems(level);
      }
      return level;
    };

    LevelGenerator.prototype.setupRoomDecoration = function(level, rooms) {
      var floor_xy, put_statue, put_torch, room, room_id, torch_xy, _results;
      _results = [];
      for (room_id in rooms) {
        if (!__hasProp.call(rooms, room_id)) continue;
        room = rooms[room_id];
        put_torch = true;
        put_statue = ROT.RNG.getUniform() < 0.15;
        if (put_torch) {
          torch_xy = this.findTorchLocation(level, room);
          if (torch_xy != null) {
            console.log(torch_xy);
            level.setTerrainAt(torch_xy, Brew.terrainFactory("WALL_TORCH"));
          } else {
            console.log("couldn't find torch spot");
          }
        }
        if (put_statue) {
          floor_xy = room.getFloors().random();
          _results.push(level.setTerrainAt(floor_xy, Brew.terrainFactory("STATUE")));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    LevelGenerator.prototype.findTorchLocation = function(level, room) {
      var floor_list, found_spot, neighbor_xy, next_t, non_room_tiles, room_tiles, t, torch_xy, tries, wall_xy, _i, _len, _ref;
      found_spot = false;
      tries = 0;
      torch_xy = null;
      floor_list = room.getFloors();
      while (tries < 10) {
        wall_xy = room.getWalls().random();
        t = level.getTerrainAt(wall_xy);
        if ((t != null) && Brew.utils.isTerrain(t, "WALL")) {
          non_room_tiles = 0;
          room_tiles = 0;
          _ref = wall_xy.getSurrounding();
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            neighbor_xy = _ref[_i];
            next_t = level.getTerrainAt(neighbor_xy);
            if ((next_t != null) && (!next_t.blocks_vision)) {
              if (__indexOf.call(floor_list, next_t) >= 0) {
                room_tiles += 1;
              } else {
                non_room_tiles += 1;
              }
            }
          }
          console.log(room_tiles, non_room_tiles);
          if (non_room_tiles === 0) {
            torch_xy = wall_xy;
            break;
          }
        }
        tries += 1;
      }
      return torch_xy;
    };

    LevelGenerator.prototype.growFlora = function(level, spawn_xy, visited_list, my_step, max_steps) {
      var neighbor_xy, t, _i, _len, _ref;
      if (my_step >= max_steps) {
        return false;
      }
      if (__indexOf.call(visited_list, spawn_xy) >= 0) {
        return false;
      }
      t = level.getTerrainAt(spawn_xy);
      if (t == null) {
        return false;
      }
      if (!Brew.utils.isTerrain(t, "FLOOR")) {
        return false;
      }
      level.setTerrainAt(spawn_xy, Brew.terrainFactory("FLOOR_MOSS"));
      visited_list.push(spawn_xy);
      _ref = spawn_xy.getAdjacent();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        neighbor_xy = _ref[_i];
        this.growFlora(level, neighbor_xy, visited_list, my_step + 1, max_steps);
      }
      return true;
    };

    LevelGenerator.prototype.makeExciting = function(level) {
      var noise, t, val, x, xy, y, _i, _j, _ref, _ref1;
      noise = new ROT.Noise.Simplex(Brew.config.width);
      for (x = _i = 0, _ref = level.width - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; x = 0 <= _ref ? ++_i : --_i) {
        for (y = _j = 0, _ref1 = level.height - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; y = 0 <= _ref1 ? ++_j : --_j) {
          val = noise.get(x / 20, y / 20);
          xy = new Coordinate(x, y);
          t = level.getTerrainAt(xy);
          if (val >= 0.75) {
            level.setTerrainAt(xy, Brew.terrainFactory("STONE"));
          } else if (val <= -0.75) {
            if (!Brew.utils.isTerrain(t, "WALL")) {
              level.setTerrainAt(xy, Brew.terrainFactory("SHALLOW_POOL"));
            }
          }
        }
      }
      return true;
    };

    LevelGenerator.prototype.setupItems = function(level) {
      var corpse_xy, def_id, extra_flasks, i, idef, intensity, item, key, min_depth, num_items, potential_items, splat, xy, _i, _j, _ref, _ref1;
      num_items = Brew.config.items_per_level;
      potential_items = [];
      _ref = Brew.item_def;
      for (def_id in _ref) {
        if (!__hasProp.call(_ref, def_id)) continue;
        idef = _ref[def_id];
        if (idef.min_depth == null) {
          min_depth = 0;
        } else {
          min_depth = idef.min_depth;
        }
        if (min_depth > level.depth) {
          continue;
        }
        if (min_depth < (level.depth - Brew.config.include_items_depth_lag)) {
          continue;
        }
        potential_items.push(def_id);
      }
      for (i = _i = 1; 1 <= num_items ? _i <= num_items : _i >= num_items; i = 1 <= num_items ? ++_i : --_i) {
        xy = level.getRandomWalkableLocation();
        def_id = potential_items.random();
        item = Brew.itemFactory(def_id);
        level.setItemAt(xy, item);
        if ((_ref1 = item.group) === Brew.groups.WEAPON || _ref1 === Brew.groups.ARMOR) {
          if (ROT.RNG.getUniform() < 0.4) {
            corpse_xy = this.getNearby(level, xy);
            if (corpse_xy != null) {
              level.setItemAt(corpse_xy, Brew.itemFactory("ARMY_CORPSE"));
              splat = Brew.utils.createSplatter(corpse_xy, 4);
              for (key in splat) {
                if (!__hasProp.call(splat, key)) continue;
                intensity = splat[key];
                level.setFeatureAt(keyToCoord(key), Brew.featureFactory("BLOOD"));
              }
            }
          }
        }
      }
      extra_flasks = Math.floor(level.depth / 2) + 1;
      for (i = _j = 0; 0 <= extra_flasks ? _j <= extra_flasks : _j >= extra_flasks; i = 0 <= extra_flasks ? ++_j : --_j) {
        xy = level.getRandomWalkableLocation();
        def_id = ["FLASK_FIRE", "FLASK_HEALTH", "FLASK_VIGOR", "FLASK_WEAKNESS", "FLASK_MIGHT", "FLASK_INVISIBLE"].random();
        item = Brew.itemFactory(def_id);
        level.setItemAt(xy, item);
      }
      if (ROT.RNG.getUniform() < Brew.config.chance_life_flask) {
        xy = level.getRandomWalkableLocation();
        level.setItemAt(xy, Brew.itemFactory("FLASK_HEALTH"));
      }
      if (ROT.RNG.getUniform() < Brew.config.chance_vigor_flask) {
        xy = level.getRandomWalkableLocation();
        level.setItemAt(xy, Brew.itemFactory("FLASK_VIGOR"));
      }
      return true;
    };

    LevelGenerator.prototype.getNearby = function(level, center_xy) {
      var i, m, potentials, t, xy, _i, _len, _ref;
      potentials = [];
      _ref = center_xy.getSurrounding();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        xy = _ref[_i];
        if (!level.checkValid(xy)) {
          continue;
        }
        t = level.getTerrainAt(xy);
        if (t.blocks_walking) {
          continue;
        }
        i = level.getItemAt(xy);
        if (i != null) {
          continue;
        }
        m = level.getMonsterAt(xy);
        if (m != null) {
          continue;
        }
        potentials.push(xy);
      }
      if (potentials.length === 0) {
        return null;
      } else {
        return potentials.random();
      }
    };

    return LevelGenerator;

  })();

  getDungeonOptions = function(user_options) {
    var options, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
    options = {
      min_room_width: (_ref = user_options != null ? user_options.min_room_width : void 0) != null ? _ref : 8,
      max_room_width: (_ref1 = user_options != null ? user_options.max_room_width : void 0) != null ? _ref1 : 18,
      min_room_height: (_ref2 = user_options != null ? user_options.min_room_height : void 0) != null ? _ref2 : 6,
      max_room_height: (_ref3 = user_options != null ? user_options.max_room_height : void 0) != null ? _ref3 : 12,
      min_circle_diameter: (_ref4 = user_options != null ? user_options.min_circle_diameter : void 0) != null ? _ref4 : 9,
      max_circle_mismatch: (_ref5 = user_options != null ? user_options.max_circle_mismatch : void 0) != null ? _ref5 : 3,
      prob_circle: (_ref6 = user_options != null ? user_options.prob_circle : void 0) != null ? _ref6 : 0.33,
      prob_cross: (_ref7 = user_options != null ? user_options.prob_cross : void 0) != null ? _ref7 : 1.0,
      fill_percentage: (_ref8 = user_options != null ? user_options.fill_percentage : void 0) != null ? _ref8 : 0.75,
      max_tries: (_ref9 = user_options != null ? user_options.max_tries : void 0) != null ? _ref9 : 500
    };
    return options;
  };

  buildDungeon = function(level, options) {
    var connection, connections, door_status, floorplan_room, floorplan_rooms, room, room_id, rooms, t_now, t_start, x, xy, y, _i, _j, _k, _l, _len, _len1, _len2, _len3, _m, _n, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
    for (x = _i = 0, _ref = level.width - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; x = 0 <= _ref ? ++_i : --_i) {
      for (y = _j = 0, _ref1 = level.height - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; y = 0 <= _ref1 ? ++_j : --_j) {
        level.setTerrainAt(new Coordinate(x, y), Brew.terrainFactory("WALL"));
      }
    }
    _ref2 = createFloorplan(level, options), floorplan_rooms = _ref2[0], connections = _ref2[1];
    rooms = {};
    t_start = new Date();
    console.log("START: build dungeon");
    for (room_id in floorplan_rooms) {
      if (!__hasProp.call(floorplan_rooms, room_id)) continue;
      floorplan_room = floorplan_rooms[room_id];
      room = getRoomFromFloorplan(floorplan_room, options);
      rooms[room_id] = room;
      _ref3 = room.getWallsOnly();
      for (_k = 0, _len = _ref3.length; _k < _len; _k++) {
        xy = _ref3[_k];
        level.setTerrainAt(xy, Brew.terrainFactory("WALL"));
      }
      _ref4 = room.getCorners();
      for (_l = 0, _len1 = _ref4.length; _l < _len1; _l++) {
        xy = _ref4[_l];
        level.setTerrainAt(xy, Brew.terrainFactory("WALL"));
      }
      _ref5 = room.getFloors();
      for (_m = 0, _len2 = _ref5.length; _m < _len2; _m++) {
        xy = _ref5[_m];
        level.setTerrainAt(xy, Brew.terrainFactory("FLOOR"));
      }
    }
    t_now = new Date();
    console.log("END: build dungeon ", t_now - t_start);
    digCorridors(level, rooms, connections);
    for (_n = 0, _len3 = connections.length; _n < _len3; _n++) {
      connection = connections[_n];
      door_status = ROT.RNG.getUniform() < 0.75 ? "DOOR_CLOSED" : "DOOR_OPEN";
      level.setTerrainAt(connection.door_xy, Brew.terrainFactory(door_status));
    }
    return [true, rooms, connections];
  };

  getOffsetXY = function(side) {
    var offset_xy;
    offset_xy = null;
    if (side === "left") {
      offset_xy = new Coordinate(-1, 0);
    } else if (side === "right") {
      offset_xy = new Coordinate(1, 0);
    } else if (side === "top") {
      offset_xy = new Coordinate(0, -1);
    } else if (side === "bottom") {
      offset_xy = new Coordinate(0, 1);
    } else {
      console.log("something terrible happened in getOffsetXY");
      debugger;
    }
    return offset_xy;
  };

  digCorridors = function(level, rooms, connections) {
    var astar, connection, corners, dest_xy, from_path, passable_fn, path, path_xy, random_points, room, start_xy, t_now, t_start, to_path, update_fn, xy, _i, _j, _k, _l, _len, _len1, _len2, _len3;
    t_start = new Date();
    console.log("START: dig corridors ");
    corners = [];
    for (_i = 0, _len = rooms.length; _i < _len; _i++) {
      room = rooms[_i];
      corners.merge(room.getCorners());
    }
    corners = (function() {
      var _j, _len1, _results;
      _results = [];
      for (_j = 0, _len1 = corners.length; _j < _len1; _j++) {
        xy = corners[_j];
        _results.push(xy.toKey());
      }
      return _results;
    })();
    passable_fn = (function(_this) {
      return function(x, y) {
        var _ref;
        xy = new Coordinate(x, y);
        if (_ref = xy.toKey(), __indexOf.call(corners, _ref) >= 0) {
          return false;
        } else {
          return true;
        }
      };
    })(this);
    random_points = {};
    path = [];
    update_fn = function(x, y) {
      return path.push(new Coordinate(x, y));
    };
    for (_j = 0, _len1 = connections.length; _j < _len1; _j++) {
      connection = connections[_j];
      start_xy = connection.door_xy.add(getOffsetXY(connection.side));
      astar = new ROT.Path.AStar(start_xy.x, start_xy.y, passable_fn, {
        topology: 4
      });
      dest_xy = rooms[connection.room_to].getFloors().random();
      path = [];
      astar.compute(dest_xy.x, dest_xy.y, update_fn);
      to_path = path.slice(0);
      start_xy = connection.door_xy.add(getOffsetXY(connection.side).multiply(-1));
      astar = new ROT.Path.AStar(start_xy.x, start_xy.y, passable_fn, {
        topology: 4
      });
      dest_xy = rooms[connection.room_from].getFloors().random();
      path = [];
      astar.compute(dest_xy.x, dest_xy.y, update_fn);
      from_path = path.slice(0);
      for (_k = 0, _len2 = from_path.length; _k < _len2; _k++) {
        path_xy = from_path[_k];
        level.setTerrainAt(path_xy, Brew.terrainFactory("FLOOR"));
      }
      for (_l = 0, _len3 = to_path.length; _l < _len3; _l++) {
        path_xy = to_path[_l];
        level.setTerrainAt(path_xy, Brew.terrainFactory("FLOOR"));
      }
    }
    t_now = new Date();
    console.log("END: dig corridors ", t_now - t_start);
    return true;
  };

  getRoomFromFloorplan = function(floorplan_room, options) {
    var is_circle_possible, min_diameter, mismatch, room;
    room = null;
    min_diameter = Math.min(floorplan_room.width, floorplan_room.height);
    mismatch = Math.abs(floorplan_room.width - floorplan_room.height);
    is_circle_possible = min_diameter >= options.min_circle_diameter && mismatch <= options.max_circle_mismatch;
    if (is_circle_possible && ROT.RNG.getUniform() < options.prob_circle) {
      room = new CircleRoom(floorplan_room.left, floorplan_room.top, min_diameter, min_diameter);
    } else {
      if (ROT.RNG.getUniform() < options.prob_cross) {
        room = createCrossRoom(floorplan_room, options);
      } else {
        room = floorplan_room;
      }
    }
    return room;
  };

  createFloorplan = function(level, options) {
    var base_room, connections, doorside, existing_room, first_room, id, is_valid_fn, level_area, max_x, max_y, min_x, min_y, new_room, new_x, new_y, overlap, placed_rooms, r, room, room_area, room_area_percent, t_now, t_start, tries, wall_xy;
    placed_rooms = {};
    is_valid_fn = (function(_this) {
      return function(r) {
        return r.left >= 0 && r.top >= 0 && r.right < level.width && r.bottom < level.height;
      };
    })(this);
    first_room = createRectangleRoom(options);
    first_room.randomizeCorner(level.width, level.height);
    placed_rooms[first_room.id] = first_room;
    connections = [];
    tries = 0;
    t_start = new Date();
    console.log("START: floorplan generation");
    level_area = level.width * level.height;
    room_area_percent = 0;
    while (room_area_percent < options.fill_percentage && tries < options.max_tries) {
      tries += 1;
      room_area = ((function() {
        var _results;
        _results = [];
        for (id in placed_rooms) {
          if (!__hasProp.call(placed_rooms, id)) continue;
          r = placed_rooms[id];
          _results.push(r.width * r.height);
        }
        return _results;
      })()).reduce(function(t, s) {
        return t + s;
      });
      room_area_percent = room_area / level_area;
      base_room = ((function() {
        var _results;
        _results = [];
        for (id in placed_rooms) {
          if (!__hasProp.call(placed_rooms, id)) continue;
          room = placed_rooms[id];
          _results.push(room);
        }
        return _results;
      })()).random();
      wall_xy = base_room.getWallsOnly().random();
      new_room = createRectangleRoom(options);
      doorside = null;
      if (wall_xy.x === base_room.left) {
        new_x = base_room.left - new_room.width + 1;
        min_y = wall_xy.y - new_room.height + 2;
        max_y = wall_xy.y - 0;
        new_y = Math.floor(ROT.RNG.getUniform() * (max_y - min_y)) + min_y;
        doorside = "left";
      } else if (wall_xy.x === base_room.right) {
        new_x = base_room.right;
        min_y = wall_xy.y - new_room.height + 2;
        max_y = wall_xy.y - 0;
        new_y = Math.floor(ROT.RNG.getUniform() * (max_y - min_y)) + min_y;
        doorside = "right";
      } else if (wall_xy.y === base_room.top) {
        new_y = base_room.top - new_room.height + 1;
        min_x = wall_xy.x - new_room.width + 2;
        max_x = wall_xy.x - 0;
        new_x = Math.floor(ROT.RNG.getUniform() * (max_x - min_x)) + min_x;
        doorside = "top";
      } else if (wall_xy.y === base_room.bottom) {
        new_y = base_room.bottom;
        min_x = wall_xy.x - new_room.width + 2;
        max_x = wall_xy.x - 0;
        new_x = Math.floor(ROT.RNG.getUniform() * (max_x - min_x)) + min_x;
        doorside = "bottom";
      } else {
        console.log("wtf?");
        console.log(wall_xy);
        console.log(new_room);
        break;
      }
      new_room.resetCornerAt(new_x, new_y);
      if (!is_valid_fn(new_room)) {
        continue;
      }
      overlap = false;
      for (id in placed_rooms) {
        if (!__hasProp.call(placed_rooms, id)) continue;
        existing_room = placed_rooms[id];
        if (existing_room.checkOverlapExcludingWalls(new_room)) {
          overlap = true;
          break;
        }
      }
      if (overlap) {
        continue;
      }
      placed_rooms[new_room.id] = new_room;
      connections.push(new Connection(base_room.id, new_room.id, wall_xy, doorside));
    }
    t_now = new Date();
    console.log("END: floorplan generation in " + tries + " tries ", t_now - t_start);
    return [placed_rooms, connections];
  };

  setupMonsters = function(level) {
    var d, def_id, dist_to_start, i, last_wgt, mdef, monster, new_wgt, num_monsters, potential_monsters, total, tries, u, weighted, wgt, xy, _i, _j, _k, _len, _ref, _ref1;
    num_monsters = Brew.config.monsters_per_level;
    potential_monsters = [];
    _ref = Brew.monster_def;
    for (def_id in _ref) {
      if (!__hasProp.call(_ref, def_id)) continue;
      mdef = _ref[def_id];
      if (mdef.min_depth == null) {
        continue;
      }
      if (mdef.min_depth > level.depth) {
        continue;
      }
      if (mdef.min_depth < (level.depth - Brew.config.include_monsters_depth_lag)) {
        continue;
      }
      potential_monsters.push(def_id);
    }
    weighted = {};
    for (_i = 0, _len = potential_monsters.length; _i < _len; _i++) {
      def_id = potential_monsters[_i];
      weighted[def_id] = Brew.monster_def[def_id].rarity;
    }
    total = ((function() {
      var _results;
      _results = [];
      for (d in weighted) {
        if (!__hasProp.call(weighted, d)) continue;
        wgt = weighted[d];
        _results.push(wgt);
      }
      return _results;
    })()).reduce(function(t, s) {
      return t + s;
    });
    last_wgt = 0;
    for (def_id in weighted) {
      if (!__hasProp.call(weighted, def_id)) continue;
      wgt = weighted[def_id];
      new_wgt = last_wgt + (wgt / total);
      weighted[def_id] = new_wgt;
      last_wgt = new_wgt;
    }
    for (i = _j = 1; 1 <= num_monsters ? _j <= num_monsters : _j >= num_monsters; i = 1 <= num_monsters ? ++_j : --_j) {
      tries = 0;
      xy = null;
      while (tries < 10) {
        xy = level.getRandomWalkableLocation();
        dist_to_start = Brew.utils.dist2d(level.start_xy, xy);
        if (dist_to_start < 10) {
          xy = null;
          tries += 1;
        } else {
          break;
        }
      }
      if (!xy) {
        continue;
      }
      u = ROT.RNG.getUniform();
      for (def_id in weighted) {
        if (!__hasProp.call(weighted, def_id)) continue;
        wgt = weighted[def_id];
        if (u < wgt) {
          monster = Brew.monsterFactory(def_id, {
            status: Brew.monster_status.WANDER
          });
          level.setMonsterAt(xy, monster);
          break;
        }
      }
    }
    if (level.depth === Brew.config.max_depth) {
      xy = level.getRandomWalkableLocation();
      level.setMonsterAt(xy, Brew.monsterFactory("TIME_MASTER", {
        status: Brew.monster_status.WANDER
      }));
    }
    if (level.depth === 0) {
      for (i = _k = 0, _ref1 = Brew.tutorial_texts.length - 1; 0 <= _ref1 ? _k <= _ref1 : _k >= _ref1; i = 0 <= _ref1 ? ++_k : --_k) {
        xy = level.getRandomWalkableLocation();
        level.setItemAt(xy, Brew.itemFactory("INFO_POINT", {
          name: "Help",
          description: Brew.tutorial_texts[i]
        }));
      }
    }
    return true;
  };

  setupPortals = function(level) {
    level.start_xy = level.getRandomWalkableLocation();
    if (level.depth > 0) {
      level.setTerrainAt(level.start_xy, Brew.terrainFactory("STAIRS_UP"));
    }
    while (true) {
      level.exit_xy = level.getRandomWalkableLocation();
      if (!level.exit_xy.compare(level.start_xy)) {
        break;
      }
    }
    level.setTerrainAt(level.exit_xy, Brew.terrainFactory("STAIRS_DOWN"));
    level.setUnlinkedPortalAt(level.exit_xy);
    return true;
  };

  createRectangleRoom = function(options) {
    var max_height, max_width, min_height, min_width, r, rand_height, rand_width;
    min_width = options.min_room_width;
    max_width = options.max_room_width;
    min_height = options.min_room_height;
    max_height = options.max_room_height;
    rand_width = Math.floor(ROT.RNG.getUniform() * (max_width - min_width)) + min_width;
    rand_height = Math.floor(ROT.RNG.getUniform() * (max_height - min_height)) + min_height;
    r = new RectangleRoom(0, 0, rand_width, rand_height);
    return r;
  };

  createCrossRoom = function(area, options) {
    var cross, min_height, min_width, random_x, random_y, room_tall, room_wide, small_height, small_width;
    min_width = options.min_room_width;
    min_height = options.min_room_height;
    small_width = Math.floor(ROT.RNG.getUniform() * (area.width - min_width)) + min_width;
    small_height = Math.floor(ROT.RNG.getUniform() * (area.height - min_height)) + min_height;
    random_x = Math.floor(ROT.RNG.getUniform() * (area.width - small_width));
    random_y = Math.floor(ROT.RNG.getUniform() * (area.height - small_height));
    room_wide = new RectangleRoom(area.left, area.top + random_y, area.width, small_height);
    room_tall = new RectangleRoom(area.left + random_x, area.top, small_width, area.height);
    cross = new CrossRoom(area.left, area.top, area.width, area.height);
    cross.room_wide = room_wide;
    cross.room_tall = room_tall;
    return cross;
  };

  Connection = (function() {
    function Connection(room_from, room_to, door_xy, side) {
      this.room_from = room_from;
      this.room_to = room_to;
      this.door_xy = door_xy;
      this.side = side;
    }

    return Connection;

  })();

  Room = (function() {
    function Room(left, top, width, height) {
      this.left = left;
      this.top = top;
      this.width = width;
      this.height = height;
      this.id = idGenerator();
      this.right = this.left + this.width - 1;
      this.bottom = this.top + this.height - 1;
    }

    Room.prototype.getFloors = function() {
      throw new Error("does not implement getFloors");
    };

    Room.prototype.getWalls = function() {
      throw new Error("does not implement getWalls");
    };

    Room.prototype.getCorners = function() {
      throw new Error("does not implement getCorners");
    };

    Room.prototype.isCorner = function(xy) {
      throw new Error("does not implement isCorner");
    };

    Room.prototype.getWallsOnly = function() {
      throw new Error("does not implement getWallsOnly");
    };

    return Room;

  })();

  RectangleRoom = (function(_super) {
    __extends(RectangleRoom, _super);

    function RectangleRoom() {
      return RectangleRoom.__super__.constructor.apply(this, arguments);
    }

    RectangleRoom.prototype.checkOverlap = function(room) {
      var no_overlap;
      no_overlap = this.left > room.right || this.right < room.left || this.top > room.bottom || this.bottom < room.top;
      return !no_overlap;
    };

    RectangleRoom.prototype.checkOverlapExcludingWalls = function(room) {
      var no_overlap;
      no_overlap = this.left >= room.right || this.right <= room.left || this.top >= room.bottom || this.bottom <= room.top;
      return !no_overlap;
    };

    RectangleRoom.prototype.isInside = function(xy) {
      return xy.x > this.left && xy.x < this.right && xy.y > this.top && xy.y < this.bottom;
    };

    RectangleRoom.prototype.getFloors = function() {
      var floors, x, y, _i, _j, _ref, _ref1, _ref2, _ref3;
      floors = [];
      for (x = _i = _ref = this.left + 1, _ref1 = this.right - 1; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; x = _ref <= _ref1 ? ++_i : --_i) {
        for (y = _j = _ref2 = this.top + 1, _ref3 = this.bottom - 1; _ref2 <= _ref3 ? _j <= _ref3 : _j >= _ref3; y = _ref2 <= _ref3 ? ++_j : --_j) {
          floors.push(new Coordinate(x, y));
        }
      }
      return floors;
    };

    RectangleRoom.prototype.getWalls = function() {
      var walls, x, y, _i, _j, _ref, _ref1, _ref2, _ref3;
      walls = [];
      for (x = _i = _ref = this.left, _ref1 = this.right; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; x = _ref <= _ref1 ? ++_i : --_i) {
        walls.push(new Coordinate(x, this.top));
        walls.push(new Coordinate(x, this.bottom));
      }
      for (y = _j = _ref2 = this.top + 1, _ref3 = this.bottom - 1; _ref2 <= _ref3 ? _j <= _ref3 : _j >= _ref3; y = _ref2 <= _ref3 ? ++_j : --_j) {
        walls.push(new Coordinate(this.left, y));
        walls.push(new Coordinate(this.right, y));
      }
      return walls;
    };

    RectangleRoom.prototype.getCorners = function() {
      var corners;
      corners = [new Coordinate(this.left, this.top), new Coordinate(this.right, this.top), new Coordinate(this.left, this.bottom), new Coordinate(this.right, this.bottom)];
      return corners;
    };

    RectangleRoom.prototype.isCorner = function(xy) {
      return this.getCorners().some((function(_this) {
        return function(c) {
          return c.compare(xy);
        };
      })(this));
    };

    RectangleRoom.prototype.getWallsOnly = function() {
      var xy;
      return (function() {
        var _i, _len, _ref, _results;
        _ref = this.getWalls();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          xy = _ref[_i];
          if (!this.isCorner(xy)) {
            _results.push(xy);
          }
        }
        return _results;
      }).call(this);
    };

    RectangleRoom.prototype.resetCornerAt = function(left, top) {
      this.top = top;
      this.left = left;
      this.bottom = this.top + this.height - 1;
      this.right = this.left + this.width - 1;
      return true;
    };

    RectangleRoom.prototype.randomizeCorner = function(area_width, area_height) {
      var new_left, new_top;
      new_left = Math.floor(ROT.RNG.getUniform() * (area_width - this.width));
      new_top = Math.floor(ROT.RNG.getUniform() * (area_height - this.height));
      return this.resetCornerAt(new_left, new_top);
    };

    return RectangleRoom;

  })(Room);

  CircleRoom = (function(_super) {
    __extends(CircleRoom, _super);

    function CircleRoom() {
      return CircleRoom.__super__.constructor.apply(this, arguments);
    }

    CircleRoom.floors = [];

    CircleRoom.prototype.getWallsOnly = function() {
      return this.getWalls();
    };

    CircleRoom.prototype.getCorners = function() {
      return [];
    };

    CircleRoom.prototype.getWalls = function() {
      var cx, cy, dist, floors, radius, walls, x, y, _i, _j, _ref, _ref1, _ref2, _ref3;
      if (this.width !== this.height) {
        debugger;
      }
      walls = [];
      floors = [];
      radius = (this.width - 1) / 2.0;
      cx = this.left + radius;
      cy = this.top + radius;
      for (x = _i = _ref = this.left, _ref1 = this.right; _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; x = _ref <= _ref1 ? ++_i : --_i) {
        for (y = _j = _ref2 = this.top, _ref3 = this.bottom; _ref2 <= _ref3 ? _j <= _ref3 : _j >= _ref3; y = _ref2 <= _ref3 ? ++_j : --_j) {
          dist = Brew.utils.dist2d_xy(cx, cy, x, y);
          if (dist >= radius) {
            walls.push(new Coordinate(x, y));
          } else {
            floors.push(new Coordinate(x, y));
          }
        }
      }
      this.floors = floors;
      return walls;
    };

    CircleRoom.prototype.getFloors = function() {
      var walls;
      if (this.floors == null) {
        walls = this.getWalls();
      }
      return this.floors;
    };

    return CircleRoom;

  })(RectangleRoom);

  CrossRoom = (function(_super) {
    __extends(CrossRoom, _super);

    function CrossRoom() {
      return CrossRoom.__super__.constructor.apply(this, arguments);
    }

    CrossRoom.room_tall = null;

    CrossRoom.room_wide = null;

    CrossRoom.prototype.getWallsOnly = function() {
      return this.getWalls();
    };

    CrossRoom.prototype.getCorners = function() {
      var corners;
      corners = [];
      corners.merge(this.room_wide.getCorners());
      corners.merge(this.room_tall.getCorners());
      return corners;
    };

    CrossRoom.prototype.getFloors = function() {
      var floors, xy, _i, _len, _ref;
      floors = [];
      floors.merge(this.room_wide.getFloors());
      _ref = this.room_tall.getFloors();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        xy = _ref[_i];
        if (__indexOf.call(floors, xy) < 0) {
          floors.push(xy);
        }
      }
      return floors;
    };

    CrossRoom.prototype.getWalls = function() {
      var tall_walls, walls, wide_walls, xy, _i, _j, _len, _len1;
      walls = [];
      wide_walls = this.room_wide.getWalls();
      tall_walls = this.room_tall.getWalls();
      for (_i = 0, _len = wide_walls.length; _i < _len; _i++) {
        xy = wide_walls[_i];
        if (!this.room_tall.isInside(xy)) {
          walls.push(xy);
        }
      }
      for (_j = 0, _len1 = tall_walls.length; _j < _len1; _j++) {
        xy = tall_walls[_j];
        if (!this.room_wide.isInside(xy)) {
          walls.push(xy);
        }
      }
      return walls;
    };

    return CrossRoom;

  })(Room);

  CorridorsRoom = (function(_super) {
    __extends(CorridorsRoom, _super);

    function CorridorsRoom() {
      return CorridorsRoom.__super__.constructor.apply(this, arguments);
    }

    CorridorsRoom.floors = [];

    CorridorsRoom.prototype.getFloors = function() {
      var cx, cy;
      cx = this.left + Math.floor(this.width / 2);
      cy = this.top + Math.floor(this.height / 2);
      return [new Coordinate(cx, cy)];
    };

    CorridorsRoom.prototype.getWalls = function() {
      return [];
    };

    CorridorsRoom.prototype.getCorners = function() {
      return [];
    };

    CorridorsRoom.prototype.isCorner = function(xy) {
      return false;
    };

    CorridorsRoom.prototype.getWallsOnly = function() {
      return this.getWalls();
    };

    return CorridorsRoom;

  })(Room);

}).call(this);

//# sourceMappingURL=levelgen.map

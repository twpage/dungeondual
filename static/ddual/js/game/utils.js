// Generated by CoffeeScript 1.7.1
(function() {
  var adjacent_offset_list, surrounding_offset_list,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Array.prototype.remove = function(e) {
    var t, _ref;
    if ((t = this.indexOf(e)) > -1) {
      return ([].splice.apply(this, [t, t - t + 1].concat(_ref = [])), _ref);
    }
  };

  Array.prototype.merge = function(other) {
    return Array.prototype.push.apply(this, other);
  };

  Number.prototype.mod = function(n) {
    return ((this % n) + n) % n;
  };

  window.MAX_INT = Math.pow(2, 53);

  window.typeIsArray = function(value) {
    return value && typeof value === 'object' && value instanceof Array && typeof value.length === 'number' && typeof value.splice === 'function' && !(value.propertyIsEnumerable('length'));
  };

  window.clone = function(obj) {
    var flags, key, newInstance;
    if ((obj == null) || typeof obj !== 'object') {
      return obj;
    }
    if (obj instanceof Date) {
      return new Date(obj.getTime());
    }
    if (obj instanceof RegExp) {
      flags = '';
      if (obj.global != null) {
        flags += 'g';
      }
      if (obj.ignoreCase != null) {
        flags += 'i';
      }
      if (obj.multiline != null) {
        flags += 'm';
      }
      if (obj.sticky != null) {
        flags += 'y';
      }
      return new RegExp(obj.source, flags);
    }
    newInstance = new obj.constructor();
    for (key in obj) {
      newInstance[key] = clone(obj[key]);
    }
    return newInstance;
  };

  window.coord_cache_adjacent = {};

  window.coord_cache_surrounding = {};

  window.coord_cache_adjacent_key = {};

  window.Coordinate = (function() {
    function Coordinate(x, y) {
      this.x = x;
      this.y = y;
      true;
    }

    Coordinate.prototype.toString = function() {
      return "(" + this.x + ", " + this.y + ")";
    };

    Coordinate.prototype.toObject = function() {
      return {
        "x": this.x,
        "y": this.y
      };
    };

    Coordinate.prototype.toKey = function() {
      return (this.y * 1024) + this.x;
    };

    Coordinate.prototype.compare = function(xy) {
      return this.x === xy.x && this.y === xy.y;
    };

    Coordinate.prototype.add = function(xy) {
      return new Coordinate(this.x + xy.x, this.y + xy.y);
    };

    Coordinate.prototype.subtract = function(xy) {
      return new Coordinate(this.x - xy.x, this.y - xy.y);
    };

    Coordinate.prototype.multiply = function(f) {
      return new Coordinate(this.x * f, this.y * f);
    };

    Coordinate.prototype.asUnit = function() {
      var unit_x, unit_y;
      unit_x = this.x === 0 ? 0 : this.x / Math.abs(this.x);
      unit_y = this.y === 0 ? 0 : this.y / Math.abs(this.y);
      return new Coordinate(unit_x, unit_y);
    };

    Coordinate.prototype.getAdjacent = function() {
      var adjacent_list, xy;
      if (coord_cache_adjacent[this.toKey()] != null) {
        return coord_cache_adjacent[this.toKey()];
      } else {
        adjacent_list = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = adjacent_offset_list.length; _i < _len; _i++) {
            xy = adjacent_offset_list[_i];
            _results.push(this.add(xy));
          }
          return _results;
        }).call(this);
        coord_cache_adjacent[this.toKey()] = adjacent_list;
        return adjacent_list;
      }
    };

    Coordinate.prototype.getSurrounding = function() {
      var surround_list, xy;
      if (coord_cache_surrounding[this.toKey()] != null) {
        return coord_cache_surrounding[this.toKey()];
      } else {
        surround_list = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = surrounding_offset_list.length; _i < _len; _i++) {
            xy = surrounding_offset_list[_i];
            _results.push(this.add(xy));
          }
          return _results;
        }).call(this);
        coord_cache_surrounding[this.toKey()] = surround_list;
        return surround_list;
      }
    };

    return Coordinate;

  })();

  window.getAdjacentKeys = function(key) {
    var key_list, xy;
    if (coord_cache_adjacent_key[key] != null) {
      return coord_cache_adjacent_key[key];
    } else {
      key_list = (function() {
        var _i, _len, _ref, _results;
        _ref = keyToCoord(key).getAdjacent();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          xy = _ref[_i];
          _results.push(xy.toKey());
        }
        return _results;
      })();
      coord_cache_adjacent_key[key] = key_list;
      return key_list;
    }
  };

  Brew.directions = {
    s: new Coordinate(0, 1),
    n: new Coordinate(0, -1),
    e: new Coordinate(1, 0),
    w: new Coordinate(-1, 0),
    se: new Coordinate(1, 1),
    ne: new Coordinate(1, -1),
    sw: new Coordinate(-1, 1),
    nw: new Coordinate(-1, -1)
  };

  adjacent_offset_list = [Brew.directions.n, Brew.directions.e, Brew.directions.s, Brew.directions.w];

  surrounding_offset_list = adjacent_offset_list.concat([Brew.directions.ne, Brew.directions.se, Brew.directions.nw, Brew.directions.sw]);

  window.coordToXY = function(x, y) {
    return new Coordinate(x, y);
  };

  window.keyToCoord = function(key) {
    return new Coordinate(key % 1024, Math.floor(key / 1024));
  };

  window.coordFromArray = function(xy_array) {
    return new Coordinate(Number(xy_array[0]), Number(xy_array[1]));
  };

  window.coordFromObject = function(xy_obj) {
    return new Coordinate(Number(xy_obj.x), Number(xy_obj.y));
  };

  window.keyFromXY = function(x, y) {
    return (y * 1024) + x;
  };

  window.Brew.utils = {
    compareThing: function(thing_a, thing_b) {
      return thing_a.id === thing_b.id;
    },
    isTerrain: function(terrain_thing, terrain_def) {
      return terrain_thing.def_id === terrain_def;
    },
    isType: function(thing, objtype) {
      return (thing != null ? thing.objtype : void 0) === objtype;
    },
    compareDef: function(thing, definition_name) {
      return thing.def_id === definition_name;
    },
    sameDef: function(thing_a, thing_b) {
      return thing_a.def_id === thing_b.def_id;
    },
    minColorRGB: function(rgb_one, rgb_two) {
      return [Math.min(rgb_one[0], rgb_two[0]), Math.min(rgb_one[1], rgb_two[1]), Math.min(rgb_one[2], rgb_two[2])];
    },
    colorRandomize: function(rgb_color, maxmin_spread) {
      var new_color, random_spread;
      random_spread = [Math.floor(ROT.RNG.getUniform() * ((maxmin_spread[0] * 2) + 1)) - maxmin_spread[0], Math.floor(ROT.RNG.getUniform() * ((maxmin_spread[1] * 2) + 1)) - maxmin_spread[1], Math.floor(ROT.RNG.getUniform() * ((maxmin_spread[2] * 2) + 1)) - maxmin_spread[2]];
      new_color = [Math.max(0, Math.min(255, rgb_color[0] + random_spread[0])), Math.max(0, Math.min(255, rgb_color[1] + random_spread[1])), Math.max(0, Math.min(255, rgb_color[2] + random_spread[2]))];
      return new_color;
    },
    dist2d: function(xy_a, xy_b) {
      return this.dist2d_xy(xy_a.x, xy_a.y, xy_b.x, xy_b.y);
    },
    dist2d_xy: function(x1, y1, x2, y2) {
      var xdiff, ydiff;
      xdiff = x1 - x2;
      ydiff = y1 - y2;
      return Math.sqrt(xdiff * xdiff + ydiff * ydiff);
    },
    calcAngle: function(start_xy, end_xy) {
      var diff_xy, theta;
      diff_xy = end_xy.subtract(start_xy);
      theta = Math.atan2(diff_xy.y, diff_xy.x);
      return theta;
    },
    forecastNextPoint: function(newtonian) {
      var diff_xy, new_xy, r, x, y;
      if (newtonian.origin_xy == null) {
        console.log("errorz");
        return;
      }
      diff_xy = newtonian.coordinates.subtract(newtonian.origin_xy);
      r = Math.sqrt(diff_xy.x * diff_xy.x + diff_xy.y * diff_xy.y);
      r += 1;
      x = Math.round(r * Math.cos(newtonian.angle));
      y = Math.round(r * Math.sin(newtonian.angle));
      new_xy = newtonian.origin_xy.add(new Coordinate(x, y));
      return new_xy;
    },
    getLineBetweenPoints: function(start_xy, end_xy) {
      var dx, dy, m, points_lst, pt, t, x0, x1, y0, y1, _ref;
      if ((start_xy.x == null) || (end_xy.x == null)) {
        console.error("invalid coords passed to getLineBetweenPoints");
      }
      _ref = [start_xy.x, start_xy.y, end_xy.x, end_xy.y], x0 = _ref[0], y0 = _ref[1], x1 = _ref[2], y1 = _ref[3];
      dy = y1 - y0;
      dx = x1 - x0;
      t = 0.5;
      points_lst = [
        {
          x: x0,
          y: y0
        }
      ];
      if (x0 === x1 && y0 === y1) {
        return points_lst;
      }
      if (Math.abs(dx) > Math.abs(dy)) {
        m = dy / (1.0 * dx);
        t += y0;
        dx = dx < 0 ? -1 : 1;
        m *= dx;
        while (x0 !== x1) {
          x0 += dx;
          t += m;
          points_lst.push({
            x: x0,
            y: Math.floor(t)
          });
        }
      } else {
        m = dx / (1.0 * dy);
        t += x0;
        dy = dy < 0 ? -1 : 1;
        m *= dy;
        while (y0 !== y1) {
          y0 += dy;
          t += m;
          points_lst.push({
            x: Math.floor(t),
            y: y0
          });
        }
      }
      return (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = points_lst.length; _i < _len; _i++) {
          pt = points_lst[_i];
          _results.push(new Coordinate(pt.x, pt.y));
        }
        return _results;
      })();
    },
    fisherYatesShuffle: function(myArray) {
      var i, j, temp_i, temp_j, _i, _ref;
      if (myArray.length === 0) {
        return [];
      } else if (myArray.length === 1) {
        return myArray;
      }
      for (i = _i = _ref = myArray.length - 1; _ref <= 1 ? _i <= 1 : _i >= 1; i = _ref <= 1 ? ++_i : --_i) {
        j = Math.floor(ROT.RNG.getUniform() * (i + 1));
        temp_i = myArray[i];
        temp_j = myArray[j];
        myArray[i] = temp_j;
        myArray[j] = temp_i;
      }
      return myArray;
    },
    getOffsetFromKey: function(keycode) {
      var offset_xy;
      offset_xy = null;
      if (__indexOf.call(Brew.keymap.MOVE_LEFT, keycode) >= 0) {
        offset_xy = Brew.directions.w;
      } else if (__indexOf.call(Brew.keymap.MOVE_RIGHT, keycode) >= 0) {
        offset_xy = Brew.directions.e;
      } else if (__indexOf.call(Brew.keymap.MOVE_UP, keycode) >= 0) {
        offset_xy = Brew.directions.n;
      } else if (__indexOf.call(Brew.keymap.MOVE_DOWN, keycode) >= 0) {
        offset_xy = Brew.directions.s;
      } else if (__indexOf.call(Brew.keymap.MOVE_UPLEFT, keycode) >= 0) {
        offset_xy = Brew.directions.nw;
      } else if (__indexOf.call(Brew.keymap.MOVE_UPRIGHT, keycode) >= 0) {
        offset_xy = Brew.directions.ne;
      } else if (__indexOf.call(Brew.keymap.MOVE_DOWNLEFT, keycode) >= 0) {
        offset_xy = Brew.directions.sw;
      } else if (__indexOf.call(Brew.keymap.MOVE_DOWNRIGHT, keycode) >= 0) {
        offset_xy = Brew.directions.se;
      }
      return offset_xy;
    },
    getOffsetInfo: function(offset_xy) {
      var info;
      info = null;
      if (offset_xy.compare(Brew.directions.n)) {
        info = {
          unicode: Brew.unicode.arrow_n,
          arrow_keycode: 38,
          numpad_keycode: 104,
          wasd_keycode: 87
        };
      } else if (offset_xy.compare(Brew.directions.s)) {
        info = {
          unicode: Brew.unicode.arrow_s,
          arrow_keycode: 40,
          numpad_keycode: 98,
          wasd_keycode: 83
        };
      } else if (offset_xy.compare(Brew.directions.e)) {
        info = {
          unicode: Brew.unicode.arrow_e,
          arrow_keycode: 39,
          numpad_keycode: 102,
          wasd_keycode: 68
        };
      } else if (offset_xy.compare(Brew.directions.w)) {
        info = {
          unicode: Brew.unicode.arrow_w,
          arrow_keycode: 37,
          numpad_keycode: 100,
          wasd_keycode: 65
        };
      } else if (offset_xy.compare(Brew.directions.se)) {
        info = {
          unicode: Brew.unicode.arrow_se,
          arrow_keycode: 34,
          numpad_keycode: 99
        };
      } else if (offset_xy.compare(Brew.directions.ne)) {
        info = {
          unicode: Brew.unicode.arrow_ne,
          arrow_keycode: 33,
          numpad_keycode: 105
        };
      } else if (offset_xy.compare(Brew.directions.sw)) {
        info = {
          unicode: Brew.unicode.arrow_sw,
          arrow_keycode: 35,
          numpad_keycode: 97
        };
      } else if (offset_xy.compare(Brew.directions.nw)) {
        info = {
          unicode: Brew.unicode.arrow_nw,
          arrow_keycode: 36,
          numpad_keycode: 103
        };
      }
      return info;
    },
    createSplatter: function(center_xy, max_dist) {
      var dist, rando, splat, splatter_level, start_x, start_y, volume, x, y, _i, _j, _ref, _ref1;
      start_x = center_xy.x - max_dist;
      start_y = center_xy.y - max_dist;
      splat = {};
      for (x = _i = start_x, _ref = start_x + max_dist * 2; start_x <= _ref ? _i <= _ref : _i >= _ref; x = start_x <= _ref ? ++_i : --_i) {
        for (y = _j = start_y, _ref1 = start_y + max_dist * 2; start_y <= _ref1 ? _j <= _ref1 : _j >= _ref1; y = start_y <= _ref1 ? ++_j : --_j) {
          dist = Brew.utils.dist2d_xy(x, y, center_xy.x, center_xy.y);
          if (dist > max_dist) {
            splatter_level = 0;
          } else {
            if (x === center_xy.x && y === center_xy.y) {
              rando = 0.99;
            } else {
              rando = ROT.RNG.getUniform();
            }
            splatter_level = (max_dist - dist) * rando;
            volume = Math.floor(splatter_level) / (max_dist - 1);
            if (volume > 0) {
              splat[keyFromXY(x, y)] = volume;
            }
          }
        }
      }
      return splat;
    },
    floodFillByKey: function(key, passable_key_lst, visited_lst, callback) {
      var next_key, _i, _len, _ref, _results;
      if (__indexOf.call(visited_lst, key) >= 0) {
        return;
      }
      if (__indexOf.call(passable_key_lst, key) < 0) {
        return;
      }
      visited_lst.push(key);
      callback(key);
      _ref = getAdjacentKeys(key);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        next_key = _ref[_i];
        _results.push(this.floodFillByKey(next_key, passable_key_lst, visited_lst, callback));
      }
      return _results;
    },
    getCirclePoints: function(center_xy, radius) {
      var ddF_x, ddF_y, f, point_lst, uk, x, x0, y, y0;
      x0 = center_xy.x;
      y0 = center_xy.y;
      point_lst = [];
      f = 1 - radius;
      ddF_x = 1;
      ddF_y = -2 * radius;
      x = 0;
      y = radius;
      point_lst.push([x0, y0 + radius]);
      point_lst.push([x0, y0 - radius]);
      point_lst.push([x0 + radius, y0]);
      point_lst.push([x0 - radius, y0]);
      while (x < y) {
        if (f >= 0) {
          y -= 1;
          ddF_y += 2;
          f += ddF_y;
        }
        x += 1;
        ddF_x += 2;
        f += ddF_x;
        point_lst.push([x0 + x, y0 + y]);
        point_lst.push([x0 - x, y0 + y]);
        point_lst.push([x0 + x, y0 - y]);
        point_lst.push([x0 - x, y0 - y]);
        point_lst.push([x0 + y, y0 + x]);
        point_lst.push([x0 - y, y0 + x]);
        point_lst.push([x0 + y, y0 - x]);
        point_lst.push([x0 - y, y0 - x]);
      }
      return (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = point_lst.length; _i < _len; _i++) {
          uk = point_lst[_i];
          _results.push(new Coordinate(uk[0], uk[1]));
        }
        return _results;
      })();
    },
    getLaserProjectileCode: function(from_xy, to_xy) {
      var slope, xdiff, ydiff;
      xdiff = to_xy.x - from_xy.x;
      ydiff = to_xy.y - from_xy.y;
      if (xdiff === 0) {
        return '|';
      } else if (ydiff === 0) {
        return '-';
      } else {
        slope = ydiff / xdiff;
        if (Math.abs(slope) >= 2) {
          return '|';
        } else if (Math.abs(slope) <= 0.5) {
          return '-';
        } else {
          if (slope < 0) {
            return '/';
          } else {
            return "\\";
          }
        }
      }
    },
    wordWrap: function(long_text, max_width) {
      return true;
    },
    mapKeyPressToActualCharacter: function(characterCode, isShiftKey) {
      var character, characterMap;
      if (characterCode === 27 || characterCode === 8 || characterCode === 9 || characterCode === 20 || characterCode === 16 || characterCode === 17 || characterCode === 91 || characterCode === 13 || characterCode === 92 || characterCode === 18) {
        return "";
      }
      characterMap = [];
      characterMap[192] = "~";
      characterMap[49] = "!";
      characterMap[50] = "@";
      characterMap[51] = "#";
      characterMap[52] = "$";
      characterMap[53] = "%";
      characterMap[54] = "^";
      characterMap[55] = "&";
      characterMap[56] = "*";
      characterMap[57] = "(";
      characterMap[48] = ")";
      characterMap[109] = "_";
      characterMap[107] = "+";
      characterMap[219] = "{";
      characterMap[221] = "}";
      characterMap[220] = "|";
      characterMap[59] = ":";
      characterMap[222] = "\"";
      characterMap[188] = "<";
      characterMap[190] = ">";
      characterMap[191] = "?";
      characterMap[32] = " ";
      character = "";
      if (isShiftKey) {
        if (characterCode >= 65 && characterCode <= 90) {
          character = String.fromCharCode(characterCode);
        } else {
          character = characterMap[characterCode];
        }
      } else {
        if (characterCode >= 65 && characterCode <= 90) {
          character = String.fromCharCode(characterCode).toLowerCase();
        } else {
          character = String.fromCharCode(characterCode);
        }
      }
      return character;
    }
  };

}).call(this);

//# sourceMappingURL=utils.map

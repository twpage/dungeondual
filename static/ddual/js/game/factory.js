// Generated by CoffeeScript 1.7.1
(function() {
  var __hasProp = {}.hasOwnProperty;

  window.Brew.terrainFactory = function(def_id, options) {
    var key, t, terrain_info, val;
    terrain_info = clone(Brew.terrain_def[def_id]);
    if (terrain_info == null) {
      console.error("terrain definition ID " + def_id + " not found");
    }
    for (key in options) {
      if (!__hasProp.call(options, key)) continue;
      val = options[key];
      terrain_info[key] = val;
    }
    t = new Brew.Terrain(terrain_info);
    t.def_id = def_id;
    if (t.color_randomize != null) {
      t.color = Brew.utils.colorRandomize(t.color, t.color_randomize);
    }
    if (t.bgcolor_randomize != null) {
      t.bgcolor = Brew.utils.colorRandomize(t.bgcolor, t.bgcolor_randomize);
    }
    return t;
  };

  window.Brew.monsterFactory = function(def_id, options) {
    var key, m, monster_info, val;
    monster_info = clone(Brew.monster_def[def_id]);
    if (monster_info == null) {
      console.error("monster definition ID " + def_id + " not found");
    }
    for (key in options) {
      if (!__hasProp.call(options, key)) continue;
      val = options[key];
      monster_info[key] = val;
    }
    m = new Brew.Monster(monster_info);
    m.def_id = def_id;
    m.createStat(Brew.stat.health, monster_info.hp);
    return m;
  };

  window.Brew.itemFactory = function(def_id, options) {
    var i, item_info, key, val;
    item_info = clone(Brew.item_def[def_id]);
    if (item_info == null) {
      console.error("item definition ID " + def_id + " not found");
    }
    for (key in options) {
      if (!__hasProp.call(options, key)) continue;
      val = options[key];
      item_info[key] = val;
    }
    i = new Brew.Item(item_info);
    i.def_id = def_id;
    return i;
  };

  window.Brew.featureFactory = function(def_id, options) {
    var f, feature_info, key, val;
    feature_info = clone(Brew.feature_def[def_id]);
    if (feature_info == null) {
      console.error("feature definition ID " + def_id + " not found");
    }
    for (key in options) {
      if (!__hasProp.call(options, key)) continue;
      val = options[key];
      feature_info[key] = val;
    }
    f = new Brew.Feature(feature_info);
    f.def_id = def_id;
    return f;
  };

}).call(this);

//# sourceMappingURL=factory.map

window.Brew.terrainFactory = (def_id, options) ->
	terrain_info = clone(Brew.terrain_def[def_id])
	if not terrain_info?
		console.error("terrain definition ID " + def_id + " not found")
	
	for own key, val of options
		terrain_info[key] = val
	
	t = new Brew.Terrain(terrain_info)
	t.def_id = def_id
	
	if t.color_randomize? 
		t.color = ROT.Color.randomize(t.color, t.color_randomize)
		
	if t.bgcolor_randomize? 
		t.bgcolor = ROT.Color.randomize(t.bgcolor, t.bgcolor_randomize)
	
	return t

window.Brew.monsterFactory = (def_id, options) -> 
	monster_info = clone(Brew.monster_def[def_id])
	if not monster_info?
		console.error("monster definition ID " + def_id + " not found")

	for own key, val of options
		monster_info[key] = val
		
	m = new Brew.Monster(monster_info)
	m.def_id = def_id
	m.createStat(Brew.stat.health, monster_info.hp)
	return m

window.Brew.itemFactory = (def_id, options) ->
	item_info = clone(Brew.item_def[def_id])
	if not item_info?
		console.error("item definition ID " + def_id + " not found")

	for own key, val of options
		item_info[key] = val
		
	i = new Brew.Item(item_info)
	i.def_id = def_id
	
	return i

window.Brew.featureFactory = (def_id, options) ->
	feature_info = clone(Brew.feature_def[def_id])
	if not feature_info?
		console.error("feature definition ID " + def_id + " not found")

	for own key, val of options
		feature_info[key] = val
	
	f = new Brew.Feature(feature_info)
	f.def_id = def_id
	return f


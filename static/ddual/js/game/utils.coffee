# javascript stuff
Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1
Array::merge = (other) -> Array::push.apply @, other
Number::mod  = (n) -> ((@%n)+n)%n
window.MAX_INT = Math.pow(2, 53)
window.typeIsArray = (value) ->
	# http://coffeescriptcookbook.com/chapters/arrays/check-type-is-array
    value and
        typeof value is 'object' and
        value instanceof Array and
        typeof value.length is 'number' and
        typeof value.splice is 'function' and
        not ( value.propertyIsEnumerable 'length' )
		
window.clone = (obj) ->
	if not obj? or typeof obj isnt 'object'
		return obj

	if obj instanceof Date
		return new Date(obj.getTime()) 

	if obj instanceof RegExp
		flags = ''
		flags += 'g' if obj.global?
		flags += 'i' if obj.ignoreCase?
		flags += 'm' if obj.multiline?
		flags += 'y' if obj.sticky?
		return new RegExp(obj.source, flags) 

	newInstance = new obj.constructor()

	for key of obj
		newInstance[key] = clone obj[key]

	return newInstance

window.coord_cache_adjacent = {}
window.coord_cache_surrounding = {}
window.coord_cache_adjacent_key = {}

# coordinate stuff
class window.Coordinate
	constructor: (@x, @y) ->
		true
	toString: ->
		return "(" + @x + ", " + @y + ")"

	toObject: ->
		return {"x": @x, "y": @y}
		
	toKey: ->
		return (@y * 1024) + @x
		
	compare: (xy) ->
		return @x == xy.x and @y == xy.y
		
	add: (xy) ->
		return new Coordinate(@x + xy.x, @y + xy.y)
		
	subtract: (xy) ->
		return new Coordinate(@x - xy.x, @y - xy.y)
		
	multiply: (f) ->
		return new Coordinate(@x * f, @y * f)
		
	asUnit: ->
		unit_x = if (@x == 0) then 0 else @x / Math.abs(@x)
		unit_y = if (@y == 0) then 0 else @y / Math.abs(@y)
		return new Coordinate(unit_x, unit_y)
		
	getAdjacent: ->
		# return a list of NESW Coordinate objects
		if coord_cache_adjacent[@toKey()]?
			return coord_cache_adjacent[@toKey()]
		else
			adjacent_list = (@add(xy) for xy in adjacent_offset_list)
			coord_cache_adjacent[@toKey()] = adjacent_list
			return adjacent_list
		
	getSurrounding: ->
		# return a list of 8 surrounding coordinates
		if coord_cache_surrounding[@toKey()]?
			return coord_cache_surrounding[@toKey()]
		else
			surround_list = (@add(xy) for xy in surrounding_offset_list)
			coord_cache_surrounding[@toKey()] = surround_list
			return surround_list
			
window.getAdjacentKeys = (key) ->
	if coord_cache_adjacent_key[key]?
		return coord_cache_adjacent_key[key]
	else
		key_list = (xy.toKey() for xy in keyToCoord(key).getAdjacent())
		coord_cache_adjacent_key[key] = key_list
		return key_list

# coordinate constants
Brew.directions = 
	s: new Coordinate(0, 1)
	n: new Coordinate(0, -1)
	e: new Coordinate(1, 0)
	w: new Coordinate(-1, 0)
	se: new Coordinate(1, 1)
	ne: new Coordinate(1, -1)
	sw: new Coordinate(-1, 1)
	nw: new Coordinate(-1, -1)

adjacent_offset_list = [Brew.directions.n, Brew.directions.e, Brew.directions.s, Brew.directions.w]

surrounding_offset_list = adjacent_offset_list.concat([Brew.directions.ne, Brew.directions.se, Brew.directions.nw, Brew.directions.sw])
		
# coordinate management
window.coordToXY = (x, y) -> 
	return new Coordinate(x, y)
	
window.keyToCoord = (key) ->
	# converts a KEY back to an {x, y} coordinate object
	return new Coordinate(key%1024, Math.floor(key / 1024))

window.coordFromArray = (xy_array) ->
	# converts an {rot.js} array [x, y] to a coord object
	return new Coordinate(Number(xy_array[0]), Number(xy_array[1]))
	
window.coordFromObject = (xy_obj) ->
	# converts a {x: x, y: y} object into a coord object, suitable for un-json'ing
	return new Coordinate(Number(xy_obj.x), Number(xy_obj.y))

window.keyFromXY = (x, y) ->
	return (y * 1024) + x
	
window.Brew.utils = 
	# object comparison stuff
	compareThing: (thing_a, thing_b) ->
		return thing_a.id == thing_b.id
	
	isTerrain: (terrain_thing, terrain_def) ->
		return terrain_thing.def_id == terrain_def
	
	isType: (thing, objtype) ->
		return thing?.objtype == objtype
	
	compareDef: (thing, definition_name) ->
		return thing.def_id == definition_name

	sameDef: (thing_a, thing_b) ->
		return thing_a.def_id == thing_b.def_id

	# rgb
	minColorRGB: (rgb_one, rgb_two) ->
		return [
			Math.min(rgb_one[0], rgb_two[0]),
			Math.min(rgb_one[1], rgb_two[1]),
			Math.min(rgb_one[2], rgb_two[2])
		]
	
	# colors
	colorRandomize: (rgb_color, maxmin_spread) ->
		# randomize a RGB color array by a random amount within a +/- spread
		# rot.js randomize uses standard deviations

		# scale spread n by (2*n)+1, then randomize, then subtract n, to get distribution of -n to +n
		random_spread = [
			Math.floor(ROT.RNG.getUniform()*((maxmin_spread[0]*2)+1)) - maxmin_spread[0],
			Math.floor(ROT.RNG.getUniform()*((maxmin_spread[1]*2)+1)) - maxmin_spread[1],
			Math.floor(ROT.RNG.getUniform()*((maxmin_spread[2]*2)+1)) - maxmin_spread[2]
		]

		new_color = [
			Math.max(0, Math.min(255, rgb_color[0] + random_spread[0])),
			Math.max(0, Math.min(255, rgb_color[1] + random_spread[1])),
			Math.max(0, Math.min(255, rgb_color[2] + random_spread[2]))
		]

		return new_color

	# math / random
	dist2d: (xy_a, xy_b) ->
		return @dist2d_xy(xy_a.x, xy_a.y, xy_b.x, xy_b.y)
	
	dist2d_xy: (x1, y1, x2, y2) ->
		# simple 2D point distance
		xdiff = (x1 - x2)
		ydiff = (y1 - y2)
		return Math.sqrt(xdiff*xdiff + ydiff*ydiff)
	
	calcAngle: (start_xy, end_xy) ->
		# use ATAN2 to calc angle between 2 points
		diff_xy = end_xy.subtract(start_xy)
		theta = Math.atan2(diff_xy.y, diff_xy.x)
		return theta
		
	forecastNextPoint: (newtonian) ->
		# a newtonian object in motion should have an origin_xy and an angle theta
		# use polar coordinates to "push" object along the same path
		if not newtonian.origin_xy?
			console.log("errorz")
			return
			
		# figure out current range
		diff_xy = newtonian.coordinates.subtract(newtonian.origin_xy)
		r = Math.sqrt(diff_xy.x*diff_xy.x + diff_xy.y* diff_xy.y)
		
		# increment r by 1 and see where that puts us
		r += 1
		
		# convert back to x, y
		x = Math.round(r * Math.cos(newtonian.angle))
		y = Math.round(r * Math.sin(newtonian.angle))
		
		new_xy = newtonian.origin_xy.add(new Coordinate(x, y))
		return new_xy
		
	getLineBetweenPoints:  (start_xy, end_xy) -> 
		if (not start_xy.x?) or (not end_xy.x?)
			console.error("invalid coords passed to getLineBetweenPoints")
			
		# Bresenham's line algorithm
		[x0, y0, x1, y1] = [start_xy.x, start_xy.y, end_xy.x, end_xy.y]
	
		dy = y1 - y0
		dx = x1 - x0
		t = 0.5
		points_lst = [{x: x0, y: y0}]
		
		if x0 == x1 and y0 == y1
			return points_lst
		
		if Math.abs(dx) > Math.abs(dy)
			m = dy / (1.0 * dx)
			t += y0
			dx = if (dx < 0) then -1 else 1
			m *= dx
	
			while x0 != x1
				x0 += dx
				t += m
				points_lst.push({x: x0, y: Math.floor(t)}) # Coordinates(x0, int(t)))
				
		else
			m = dx / (1.0 * dy)
			t += x0
			dy = if (dy < 0) then -1 else 1
			m *= dy
			
			while y0 != y1
				y0 += dy
				t += m
				points_lst.push({x: Math.floor(t), y: y0}) # Coordinates(int(t), y0))
		
		return (new Coordinate(pt.x, pt.y) for pt in points_lst)
	
	fisherYatesShuffle: (myArray) ->
		# in-line shuffle an array 
		if myArray.length == 0 
			return []
		else if myArray.length == 1
			return myArray
		
		for i in [myArray.length-1..1]
			j = Math.floor(ROT.RNG.getUniform()*(i+1))
			temp_i = myArray[i]
			temp_j = myArray[j]
			myArray[i] = temp_j
			myArray[j] = temp_i
			
		return myArray

	getOffsetFromKey: (keycode) ->
		# return an offset coordinate object given a keypress

		offset_xy = null

		if keycode in Brew.keymap.MOVE_LEFT
			offset_xy = Brew.directions.w

		else if keycode in Brew.keymap.MOVE_RIGHT
			offset_xy = Brew.directions.e

		else if keycode in Brew.keymap.MOVE_UP
			offset_xy = Brew.directions.n

		else if keycode in Brew.keymap.MOVE_DOWN
			offset_xy = Brew.directions.s

		else if keycode in Brew.keymap.MOVE_UPLEFT
			offset_xy = Brew.directions.nw 

		else if keycode in Brew.keymap.MOVE_UPRIGHT
			offset_xy = Brew.directions.ne 

		else if keycode in Brew.keymap.MOVE_DOWNLEFT
			offset_xy = Brew.directions.sw

		else if keycode in Brew.keymap.MOVE_DOWNRIGHT
			offset_xy = Brew.directions.se

		return offset_xy

	getOffsetInfo: (offset_xy) ->
		info = null
			
		if offset_xy.compare(Brew.directions.n)
			info =
				unicode: Brew.unicode.arrow_n
				arrow_keycode: 38
				numpad_keycode: 104
				wasd_keycode: 87
		else if offset_xy.compare(Brew.directions.s)
			info =
				unicode: Brew.unicode.arrow_s
				arrow_keycode: 40
				numpad_keycode: 98
				wasd_keycode: 83
		else if offset_xy.compare(Brew.directions.e)
			info =
				unicode: Brew.unicode.arrow_e
				arrow_keycode: 39
				numpad_keycode: 102
				wasd_keycode: 68
		else if offset_xy.compare(Brew.directions.w)
			info =
				unicode: Brew.unicode.arrow_w
				arrow_keycode: 37
				numpad_keycode: 100
				wasd_keycode: 65
		else if offset_xy.compare(Brew.directions.se)
			info =
				unicode: Brew.unicode.arrow_se
				arrow_keycode: 34
				numpad_keycode: 99
		else if offset_xy.compare(Brew.directions.ne)
			info =
				unicode: Brew.unicode.arrow_ne
				arrow_keycode: 33
				numpad_keycode: 105
		else if offset_xy.compare(Brew.directions.sw)
			info =
				unicode: Brew.unicode.arrow_sw
				arrow_keycode: 35
				numpad_keycode: 97
		else if offset_xy.compare(Brew.directions.nw)
			info =
				unicode: Brew.unicode.arrow_nw
				arrow_keycode: 36
				numpad_keycode: 103
				
		return info
	
	createSplatter: (center_xy, max_dist) ->
		# return a dictionary of xy-keys and splatter intensities
		start_x = center_xy.x - max_dist
		start_y = center_xy.y - max_dist
		splat = {}
		
		for x in [start_x..start_x+max_dist*2]
			for y in [start_y..start_y+max_dist*2]
				
				dist = Brew.utils.dist2d_xy(x, y, center_xy.x, center_xy.y)
				
				if dist > max_dist
					splatter_level = 0
				
				else
					# always include center point
					if (x == center_xy.x and y == center_xy.y)
						rando = 0.99
						
					else 
						rando = ROT.RNG.getUniform()

					splatter_level = (max_dist - dist) * rando
					volume = Math.floor(splatter_level) / (max_dist - 1)
					if volume > 0
						splat[keyFromXY(x, y)] = volume

		return splat
		
	floodFillByKey: (key, passable_key_lst, visited_lst, callback) ->
		# recursively crawls tiles
		
		# stop condition: already visited
		if key in visited_lst
			return
		
		# stop condition: tile not passable
		if key not in passable_key_lst
			return
			
		visited_lst.push(key)
		callback(key)
		
		for next_key in getAdjacentKeys(key)
			@floodFillByKey(next_key, passable_key_lst, visited_lst, callback)

	getCirclePoints: (center_xy, radius) ->
		#  Returns the points that make up the radius of a circle
		# http://en.wikipedia.org/wiki/Midpoint_circle_algorithm
		x0 = center_xy.x
		y0 = center_xy.y
		
		point_lst = []
		
		f = 1 - radius
		ddF_x = 1
		ddF_y = -2 * radius
		x = 0
		y = radius
		
		point_lst.push([x0, y0 + radius])
		point_lst.push([x0, y0 - radius])
		point_lst.push([x0 + radius, y0])
		point_lst.push([x0 - radius, y0])
		
		while (x < y)
			if (f >= 0)
				y -= 1
				ddF_y += 2
				f += ddF_y
				
			x += 1
			ddF_x += 2
			f += ddF_x
			point_lst.push([x0 + x, y0 + y])
			point_lst.push([x0 - x, y0 + y])
			point_lst.push([x0 + x, y0 - y])
			point_lst.push([x0 - x, y0 - y])
			point_lst.push([x0 + y, y0 + x])
			point_lst.push([x0 - y, y0 + x])
			point_lst.push([x0 + y, y0 - x])
			point_lst.push([x0 - y, y0 - x])
			
		return (new Coordinate(uk[0], uk[1]) for uk in point_lst)
		
	getLaserProjectileCode: (from_xy, to_xy) ->
		# utility function to draw lasers as |-\/ depending on direction
		xdiff = to_xy.x - from_xy.x
		ydiff = to_xy.y - from_xy.y
		
		if xdiff == 0
			return '|'
		else if ydiff == 0
			return '-'
		else
			# determine based on slope
			slope = (ydiff / xdiff)
			
			if Math.abs(slope) >= 2
				return '|'
			else if Math.abs(slope) <= 0.5
				return '-'
			else
				return if (slope < 0) then '/' else "\\"

	wordWrap: (long_text, max_width) ->
		# word wrap some text - return an array of strings up to max_width
		true

	mapKeyPressToActualCharacter: (characterCode, isShiftKey) ->
		# http://stackoverflow.com/questions/3337188/get-key-char-value-from-keycode-with-shift-modifier
		if characterCode in [27, 8, 9, 20, 16, 17, 91, 13, 92, 18]
        	return ""

    	characterMap = []
		characterMap[192] = "~"
		characterMap[49] = "!"
		characterMap[50] = "@"
		characterMap[51] = "#"
		characterMap[52] = "$"
		characterMap[53] = "%"
		characterMap[54] = "^"
		characterMap[55] = "&"
		characterMap[56] = "*"
		characterMap[57] = "("
		characterMap[48] = ")"
		characterMap[109] = "_"
		characterMap[107] = "+"
		characterMap[219] = "{"
		characterMap[221] = "}"
		characterMap[220] = "|"
		characterMap[59] = ":"
		characterMap[222] = "\""
		characterMap[188] = "<"
		characterMap[190] = ">"
		characterMap[191] = "?"
		characterMap[32] = " "
    	
		character = ""
		if isShiftKey
			if ( characterCode >= 65 and characterCode <= 90 )
				character = String.fromCharCode(characterCode)
			else
				character = characterMap[characterCode]
		else
			if ( characterCode >= 65 and characterCode <= 90 )
				character = String.fromCharCode(characterCode).toLowerCase()
			else
				character = String.fromCharCode(characterCode)

		return character

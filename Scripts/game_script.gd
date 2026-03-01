extends Node

const GENERATE_DIST = 35
const STONE_LAYER = 200.0
const MAX_CAVE_SIZE = 250
#const PATTERNS = {
	#"Shop": [Vector2i(14, 14), Vector2i(15, 15)]
#}

@onready var tile_map = $Node2D/TileMapLayer
@export var player: CharacterBody2D

var deepest_generated = 0

var rng = RandomNumberGenerator.new()

const CAVE_DIRS =  [Vector2i(0, -1),
		Vector2i(-1, 0),          Vector2i(1, 0),
					Vector2i(0, 1)]

# Vector2i(3, 0) is CAVE AIR
func generate_cave_air(pos : Vector2i, size : int) -> int:
	var dirs = CAVE_DIRS.duplicate(true) 
	dirs.shuffle()
	for dir in dirs:
		if rng.randi_range(0, 25) != 0:
			var new = pos + dir
			if tile_map.get_cell_source_id(new) == -1:
				tile_map.set_cell(new, 0, Vector2i(0, 2))
				return generate_cave_air(new, size + 1)
		else:
			return 0
	return size + 1

func fill_tile(atlas : Vector2i, v1 : Vector2i, v2 : Vector2i):
	for y in range(v1.y, v2.y):
		for x in range(v1.x, v2.x):
			tile_map.set_cell(Vector2i(x, y), 0, atlas)

func tick():
	var center = tile_map.local_to_map(player.position)
	for y in range(center.y - floor(GENERATE_DIST / 2.0), center.y + floor(GENERATE_DIST / 2.0)):
		deepest_generated = max(deepest_generated, y)
		if deepest_generated % 100 == 0:
			var shop_pos = Vector2i(center.x, deepest_generated)
			fill_tile(Vector2i(0, 2), shop_pos, shop_pos + Vector2i(2, 2))
			tile_map.set_cell(shop_pos, 0, Vector2i(14, 14))
			deepest_generated += 1
		if y == 1: # Grass Layer
			for x in range(center.x - floor(GENERATE_DIST / 2.0), center.x + floor(GENERATE_DIST / 2.0)):
				var pos = Vector2i(x, y)
				if tile_map.get_cell_source_id(pos) == -1:
					tile_map.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
		elif y > 1: # Dirt layer
			for x in range(center.x - floor(GENERATE_DIST / 2.0), center.x + floor(GENERATE_DIST / 2.0)):
				var tile_to_generate = Vector2i(0, 0)
				if rng.randi_range(0, max(25.0 * (1.0 - float(y)/STONE_LAYER), 0)) == 0:
					tile_to_generate = Vector2i(1, 0)
				var pos = Vector2i(x, y)
				if tile_map.get_cell_source_id(pos) == -1:
					if rng.randi_range(0, 75) == 0: # cave seed
						tile_map.set_cell(Vector2i(x, y), 0, Vector2i(0, 2))
						generate_cave_air(Vector2i(x, y), 0)
						
					else:
						tile_map.set_cell(Vector2i(x, y), 0, tile_to_generate)
					
					

func _ready() -> void:
	$Tick.timeout.connect(tick)

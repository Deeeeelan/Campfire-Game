extends Node

const GENERATE_DIST = 40
const STONE_LAYER = 200.0
const MAX_CAVE_SIZE = 250
#const PATTERNS = {
	#"Shop": [Vector2i(14, 14), Vector2i(15, 15)]
#}

@onready var tile_map = $Node2D/TileMapLayer
@export var player: CharacterBody2D
@export var ceiling_y = -170
@export var ceiling_speed = 10

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
			if deepest_generated == 0:
				shop_pos = Vector2i(0, -1)
			fill_tile(Vector2i(0, 2), shop_pos, shop_pos + Vector2i(2, 2))
			tile_map.set_cell(shop_pos, 0, Vector2i(14, 14))
			tile_map.set_cell(shop_pos + Vector2i(0, 2), 0, Vector2i(0, 4))
			tile_map.set_cell(shop_pos + Vector2i(1, 2), 0, Vector2i(0, 4))
			deepest_generated += 1
		if deepest_generated % 1000 == 0:
			var bunker_pos = Vector2i(center.x, deepest_generated)
			fill_tile(Vector2i(0, 2), bunker_pos, bunker_pos + Vector2i(2, 2))
			tile_map.set_cell(bunker_pos, 0, Vector2i(12, 14))
			tile_map.set_cell(bunker_pos + Vector2i(0, 2), 0, Vector2i(0, 4))
			tile_map.set_cell(bunker_pos + Vector2i(1, 2), 0, Vector2i(0, 4))
			deepest_generated += 1
		if y == 1: # Grass Layer
			for x in range(center.x - floor(GENERATE_DIST / 2.0), center.x + floor(GENERATE_DIST / 2.0)):
				var pos = Vector2i(x, y)
				if tile_map.get_cell_source_id(pos) == -1:
					tile_map.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
		elif y > 1: # Dirt layer
			for x in range(center.x - floor(GENERATE_DIST / 2.0), center.x + floor(GENERATE_DIST / 2.0)):
				var tile_to_generate = Vector2i(0, 0)
				if y > 600 and rng.randi_range(0, 100) == 0:
					tile_to_generate = Vector2i(7, 0)
				elif y > 400 and rng.randi_range(0, 75) == 0:
					tile_to_generate = Vector2i(6, 0)
				elif y > 250 and rng.randi_range(0, 20) == 0:
					tile_to_generate = Vector2i(5, 0)
				elif y > 100 and rng.randi_range(0, 15) == 0:
					tile_to_generate = Vector2i(4, 0)
				elif rng.randi_range(0, 15) == 0:
					tile_to_generate = Vector2i(3, 0)
				elif y >= 200 or rng.randi_range(0, max(25.0 * (1.0 - float(y)/STONE_LAYER), 0)) == 0:
					tile_to_generate = Vector2i(1, 0)
				if y > 100 and rng.randi_range(0, 45) == 0:
					tile_to_generate = Vector2i(0, 5)
				elif y > 250 and rng.randi_range(0, 35) == 0:
					tile_to_generate = Vector2i(0, 6)
				elif y > 400 and rng.randi_range(0, 15) == 0:
					tile_to_generate = Vector2i(0, 6)
				
				if y > 100 and rng.randi_range(0, 7) == 0:
					tile_to_generate = Vector2i(0, 4)
				
				var pos = Vector2i(x, y)
				if tile_map.get_cell_source_id(pos) == -1:
					if rng.randi_range(0, 75) == 0: # cave seed
						tile_map.set_cell(Vector2i(x, y), 0, Vector2i(0, 2))
						generate_cave_air(Vector2i(x, y), 0)
						
					else:
						tile_map.set_cell(Vector2i(x, y), 0, tile_to_generate)

func _ready() -> void:
	$Tick.timeout.connect(tick)
	var tween = get_tree().create_tween()
	tween.tween_property($MusicPlayer, "volume_db", 0, 2)
	
func _process(delta: float) -> void:
	ceiling_y += ceiling_speed * delta
	$Node2D/DeathCeiling.position = Vector2($Node2D/DeathCeiling.position.x, ceiling_y)
	if player.position.y < ceiling_y:
		player.health = 0
	if player.position.y - ceiling_y > 500.0:
		ceiling_y = player.position.y - 500.0

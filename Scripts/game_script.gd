extends Node

@onready var tile_map = $Node2D/TileMapLayer


func generate_terrain(origin : Vector2i, start_depth : int, width : int, depth: int):
	print("Generating", origin, width)
	 # Placeholder, this needs to be streamed/generated as the player moves later
	for y in range(origin.y, depth):
		for x in range(origin.x, width):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
			
	

func _ready() -> void:
	generate_terrain(Vector2i(0, 2), 2, 100, 100)

func _process(delta: float) -> void:
	pass

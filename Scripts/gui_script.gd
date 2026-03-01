extends Control

@export var menu_open: bool = false
@onready var pause_screen = $PauseScreen
@onready var inner = $Inner
@export var player: CharacterBody2D
@export var tile_map: TileMapLayer

func quit():
	get_tree().quit()

func _ready() -> void:
	pause_screen.visible = false
	pause_screen.get_node("QuitButton").pressed.connect(quit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		pause_screen.visible = not pause_screen.visible
		menu_open = not menu_open
		
		if menu_open:
			Engine.time_scale = 0
		else:
			Engine.time_scale = 1

func _process(_delta: float) -> void:
	inner.get_node("DepthLabel").text = "Depth: " + str(tile_map.local_to_map(player.position).y)
	inner.get_node("HealthLabel").text = "Health: " + str(player.health)
	inner.get_node("GoldLabel").text = "Gold: " + str(player.gold)

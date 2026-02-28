extends Node

var game_path = "res://Scenes/Game.tscn"

@onready var start_button = $StartButton

func start():
	get_tree().change_scene_to_file(game_path)

func _ready() -> void:
	start_button.pressed.connect(start)

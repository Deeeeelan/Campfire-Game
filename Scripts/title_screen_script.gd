extends Node

var game_path = "res://Scenes/Game.tscn"

@onready var start_button = $StartButton
@onready var quit_button = $QuitButton
func start():
	get_tree().change_scene_to_file(game_path)
func quit():
	get_tree().quit()

func _ready() -> void:
	start_button.pressed.connect(start)
	quit_button.pressed.connect(quit)

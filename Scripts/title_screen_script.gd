extends Node

var game_path = "res://Scenes/Game.tscn"
var intro_path = "res://Scenes/Intro.tscn"

@onready var start_button = $StartButton
@onready var quit_button = $QuitButton

func start():
	get_tree().change_scene_to_file(intro_path)
	
func quit():
	get_tree().quit()

func _input(event) -> void:
	if event.is_action_released("Escape"):
		quit()
	elif event is InputEventMouseButton:
		if event.is_released():
			if event.button_index == MOUSE_BUTTON_LEFT:
				start()
	elif event is InputEventKey:
		if event.is_released():
			start()
